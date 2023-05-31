
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/gcp"
      version = "~> 4.64.0"
    }
  }
}



# Create a service account with BigQuery and Cloud Storage permissions
resource "google_service_account" "query_runner" {
  account_id   = "query-runner"
  display_name = "Query Runner"
}

resource "google_project_iam_custom_role" "cfunction_role" {
  role_id     = "customCFunctionRole"
  title       = "Custom Cloud Function Role"
  description = "More granular permissions other than default @appspot SA"
  permissions = [
    "storage.buckets.get",
    "storage.objects.create",
    "storage.multipartUploads.create",
    "storage.objects.get",
    "storage.objects.list",
    "bigquery.datasets.get",
    "bigquery.tables.getData",
    "bigquery.jobs.create",
    "bigquery.jobs.get",
    "bigquery.jobs.list",
    "bigquery.tables.list",
    "logging.logEntries.create",
  ]
}


resource "google_project_iam_member" "query_runner_permissions" {
  role    = google_project_iam_custom_role.cfunction_role.id
  project = var.gcp_project
  member  = "serviceAccount:${google_service_account.query_runner.email}"

}


resource "google_service_account" "query_runner_invoker" {
  account_id   = "query-runner-invoker"
  display_name = "Query Runner Invoker"
}


resource "google_cloudfunctions_function_iam_member" "invoker_role" {
  project        = google_cloudfunctions_function.query_runner.project
  region         = google_cloudfunctions_function.query_runner.region
  cloud_function = google_cloudfunctions_function.query_runner.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.query_runner_invoker.email}"
}

/*
resource "google_project_iam_member" "query_runner_inovker_permissions" {
  role    = "roles/cloudscheduler.admin"
  project = var.gcp_project
  member = "serviceAccount:${google_service_account.query_runner_invoker.email}"

}
*/

resource "google_storage_bucket" "sql_src_bucket" {
  name     = "src-sql-files-${var.gcp_project}"
  location = var.gcp_region
}


resource "google_storage_bucket" "result_bucket" {
  name     = "sql-results-${var.gcp_project}"
  location = var.gcp_region
}

resource "google_storage_bucket" "src_code_bucket" {
  name     = "gcf-src-${var.gcp_project}"
  location = var.gcp_region
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./tmp/source.zip"
}

# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "zip" {
  source       = data.archive_file.source.output_path
  content_type = "application/zip"

  name   = "src-${data.archive_file.source.output_md5}.zip"
  bucket = google_storage_bucket.src_code_bucket.name

}


# Set up Cloud Function to run query and export result to Cloud Storage
resource "google_cloudfunctions_function" "query_runner" {
  name                  = "query_runner"
  runtime               = "python38"
  source_archive_bucket = google_storage_bucket.src_code_bucket.name
  source_archive_object = google_storage_bucket_object.zip.name
  trigger_http          = true
  entry_point           = "main"
  service_account_email = google_service_account.query_runner.email

  environment_variables = {
    SOURCE_BUCKET_NAME = google_storage_bucket.sql_src_bucket.name
    RESULT_BUCKET_NAME = google_storage_bucket.result_bucket.name
    QUERY_LIST         = jsonencode(var.query_file_list)
    PROJECT_ID         = var.gcp_project
  }
}


# Set up Cloud Scheduler job to trigger Cloud Function on a schedule
resource "google_cloud_scheduler_job" "schedule_query" {
  name      = "schedule_query"
  schedule  = var.schedule
  time_zone = "UTC"

  http_target {
    uri         = google_cloudfunctions_function.query_runner.https_trigger_url
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.query_runner_invoker.email
    }
  }

}
