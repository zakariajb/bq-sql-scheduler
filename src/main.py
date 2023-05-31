import os
from google.cloud import bigquery
from google.cloud import storage
import simplejson as json

def main(argv=None):
    client = bigquery.Client()
    storage_client = storage.Client()
    
    sql_files_to_execute = json.loads(os.environ.get('QUERY_LIST'))
    src_bucket = storage_client.bucket(os.environ.get('SOURCE_BUCKET_NAME'))
    
    for sql_file in sql_files_to_execute:
        blob = src_bucket.get_blob(f'{sql_file}')
    
        if blob is not None:
            print(f'Executing SQL file: {sql_file}')
            
            # destination des resultats
            bucket_name = os.environ.get('RESULT_BUCKET_NAME')
            blob_name = f'{sql_file}.csv'
            destination_uri = f'gs://{bucket_name}/{blob_name}'
            
            # execution de la requete 
            sql = blob.download_as_text().strip() 
            query_job = client.query(sql)
            destination_blob = storage_client.bucket(bucket_name).blob(blob_name)
            destination_blob.content_type = 'text/csv'
            query_job.result().to_dataframe().to_csv(destination_blob.open('w'), index=False)
            
            # Verification dans cloud storage
            bucket = storage_client.get_bucket(bucket_name)
            blob = bucket.get_blob(blob_name)
            print(f'resultats au : {blob.public_url}')
            return 0
        
        else:
            print(f'fichier non existant: {sql_file}')
            return -1
    

    
    
