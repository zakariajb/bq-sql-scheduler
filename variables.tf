variable "gcp_project" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "gcp_region" {
  type        = string
  description = "Google Cloud Region"
}

variable "dataset_id" {
  type        = string
  description = "ID du dataset pour l'execution des requets sql"
}

variable "table_id" {
  type        = string
  description = "ID de la table pour l'execution des requets sql"
}

variable "query_file_list" {
  type        = list(string)
  default     = []
  description = "Fichiers sql à executer"

}

variable "schedule" {
  type        = string
  description = "Freqeuence d'execution des fichiers sql"
  default     = "0 0 1 * *"
}