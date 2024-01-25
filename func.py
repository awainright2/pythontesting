import io
#import os
import json
import logging
logging.getLogger().info('Trying to import pyodbc')
import pyodbc

from fdk import response

def handler(ctx, data: io.BytesIO=None):
    logging.getLogger().info('Testing')
    name = "World"
    try:
        body = json.loads(data.getvalue())
        name = body.get("name")
    except (Exception, ValueError) as ex:
        logging.getLogger().info('error parsing json payload: ' + str(ex))

    logging.getLogger().info("Inside Python Hello World function")
    isConnected = sqlConnection()
    return response.Response(
        ctx, response_data=json.dumps(
            {"Message": "{0}".format(isConnected)}),
            #{"Message": "test"}),
        headers={"Content-Type": "application/json"}
    )

def sqlConnection():
    server = 'GEODBDEV'
    database = 'Apps'
    username = 'wainriac-lsa'
    password = 'mYaPP1ei$GolDen'
    logging.info('Driver info')
    logging.getLogger().info(pyodbc.drivers())
    logging.info('Datasources')
    logging.getLogger().info(pyodbc.dataSources())

    try:
        logging.info('Attempting database connection...')
        #drivers = pyodbc.drivers()
        #logging.info('Drivers' + drivers)
        
        conn = pyodbc.connect(
    'DRIVER={ODBC Driver 17 for SQL Server};SERVER='+server+';PORT=1443;DATABASE='+database+';UID='+username+';PWD='+password, autocommit=True)
        #conn = pyodbc.connect('DRIVER={FreeTDS};SERVER='+server+',1433;DATABASE='+database+';UID='+username+';PWD='+ password)
        logging.info('Database connection successful')
        # Additional code for executing SQL statements or working with the database goes here
        # For example: cursor = conn.cursor()
        #              cursor.execute('SELECT * FROM your_table')
        #              rows = cursor.fetchall()
        #              print(rows)
        conn.close()  # Close the connection when done
    except pyodbc.Error as ex:
        error_message = "An error occurred: " + str(ex)
        logging.error(error_message)
        return error_message
        # Handle the error as per your application's requirements
    return "Connection successful"