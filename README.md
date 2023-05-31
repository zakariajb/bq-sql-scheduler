# bq-sql-scheduler

This module allows you to execute sql queries in big queries, simply by specifying the list of sql files (in the source bucket) to be executed, the result of which is then stored in the result bucket.


## Variables

| Argument | Description |
| -------- | ----------- |
| gcp_project | gcp project |
| gcp_region | gcp region |
| dataset_id | target dataset ID |
| table_id | target table  ID |
| query_file_list | SQL file list |
| schedule | schedule <`* * * * *>|



```HCL

module "bq_query" {
  source      = "path"
  gcp_project = "project_id"
  gcp_region = "europe-west1"
  dataset_id = "my-dataset-id"
  table_id = "my-dataset-id.my-table-id"
  query_file_list = ["all-info.sql"]

  providers = {
    google = google.alias
  }


}

```
