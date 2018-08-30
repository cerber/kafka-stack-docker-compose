#!/usr/bin/env python2.7

import csv, json
from pprint import pprint
from fastavro import schemaless_writer, parse_schema
from StringIO import StringIO

def int_or_null(n):
    try:
        return {'int': int(n)}
    except ValueError:
        return {'null': None}

def str_or_null(s):
    if s != 'NULL':
        return {'string': s}
    else:
        return {'null': None}

with open('./config/test/airbnb_session_data_value.json') as schema_file:
    schema_dict = json.load(schema_file)
    schema = parse_schema(schema_dict)

with open('./config/test/airbnb_session_data.txt') as csvfile:
    csvreader = csv.DictReader(csvfile, delimiter='|')
    
    def row_update(row):
        row.update({'dim_session_number': int_or_null(row['dim_session_number'])})
        row.update({'did_search': int_or_null(row['did_search'])})
        row.update({'sent_message': int_or_null(row['sent_message'])})
        row.update({'sent_booking_request': int_or_null(row['sent_booking_request'])})
        row.update({'next_dim_session_number': int_or_null(row['next_dim_session_number'])})
        row.update({'next_did_search': int_or_null(row['next_did_search'])})
        row.update({'next_sent_message': int_or_null(row['next_sent_message'])})
        row.update({'next_sent_booking_request': int_or_null(row['next_sent_booking_request'])})

        row.update({'ds': str_or_null(row['ds'])})
        row.update({'ts_min': str_or_null(row['ts_min'])})
        row.update({'ts_max': str_or_null(row['ts_max'])})
        row.update({'next_ds': str_or_null(row['next_ds'])})
        row.update({'next_ts_min': str_or_null(row['next_ts_min'])})
        row.update({'next_ts_max': str_or_null(row['next_ts_max'])})

        row.update({'id_session': str_or_null(row['id_session'])})
        row.update({'dim_user_agent': str_or_null(row['dim_user_agent'])})
        row.update({'dim_device_app_combo': str_or_null(row['dim_device_app_combo'])})
        row.update({'next_id_session': str_or_null(row['next_id_session'])})
        row.update({'next_dim_user_agent': str_or_null(row['next_dim_user_agent'])})
        row.update({'next_dim_device_app_combo': str_or_null(row['next_dim_device_app_combo'])})
        
        return row

    for row in csvreader:
        
        # rows = [[row[0],row[1],row[2],row[3],row[4],row[5],row[6],row[7],int_or_null(row[8]),int_or_null(row[9]),int_or_null(row[10]),row[11],int_or_null(row[12]),row[13],row[14],row[15],row[16],row[17],int_or_null(row[18]),int_or_null(row[19]),int_or_null(row[20])] for row in csvreader]
        avro_row = row_update(row)
        # out = StringIO()
        # pprint(row)
        # schemaless_writer(out, schema, row)
        print('\t'.join(map(str, [json.dumps({'id_session': row['id_session']}), json.dumps(avro_row)])))


