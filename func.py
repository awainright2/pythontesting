import io
import json
import logging
import pyodbc

from fdk import response


def handler(ctx, data: io.BytesIO=None):
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
        headers={"Content-Type": "application/json"}
    )

def sqlConnection():
    server = '10.23.9.206'
    database = 'Apps'
    username = 'wainriac-lsa'
    password = 'mYaPP1ei$GolDen'

    try:
        conn = pyodbc.connect('DRIVER={SQL Server};SERVER='+server+',1433;DATABASE='+database+';UID='+username+';PWD='+ password)
        # Additional code for executing SQL statements or working with the database goes here
        # For example: cursor = conn.cursor()
        #              cursor.execute('SELECT * FROM your_table')
        #              rows = cursor.fetchall()
        #              print(rows)
        conn.close()  # Close the connection when done
    except pyodbc.Error as ex:
        return "An error occurred:", ex
        # Handle the error as per your application's requirements
     return "Connection successful"