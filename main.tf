# 使用random產生亂數
resource "random_id" "bucket_prefix" {
  byte_length = 8
}

# 產生存放程式碼的GCS
resource "google_storage_bucket" "cloud_function_bucket" {
  name                        = "${var.func_name}-bucket-${random_id.bucket_prefix.hex}"
  location                    = "ASIA"
  uniform_bucket_level_access = true
}

# 將 src 的檔案壓縮成 zip
data "archive_file" "src" {
  type        = "zip"
  source_dir  = "${path.root}/src/"
  output_path = "${path.root}/generated/${var.func_name}.zip"
}

# 將 zip 上傳到 GCP 上，提供 cloud function 部署
resource "google_storage_bucket_object" "archive" {
  name   = "${data.archive_file.src.output_md5}.zip"
  bucket = google_storage_bucket.cloud_function_bucket.name
  source = data.archive_file.src.output_path

  metadata = {
    ManagedBy = "Terraform"
  }
}

# cloud function 程式碼
resource "google_cloudfunctions_function" "pong_function" {
  name                = var.func_name
  description         = "tf-cloud-function"
  runtime             = "python39"
  available_memory_mb = 256
  timeout             = 60

  source_archive_bucket = google_storage_bucket.cloud_function_bucket.name
  source_archive_object = google_storage_bucket_object.archive.name

  trigger_http = true
  entry_point  = "handler"

  depends_on = [
    google_storage_bucket.cloud_function_bucket,
    google_storage_bucket_object.archive
  ]
}

# IAM 所有人都可以去 access
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.pong_function.project
  region         = google_cloudfunctions_function.pong_function.region
  cloud_function = google_cloudfunctions_function.pong_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
