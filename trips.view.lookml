- explore: trips
  sql_always_where: |
    ${location_valid}

- view: trips
#   derived_table:
#     sql: |
#       SELECT
#         pickup_datetime,
#         dropoff_datetime,
#         store_and_fwd_flag,
#         pickup_longitude,
#         pickup_latitude,
#         dropoff_longitude,
#         dropoff_latitude,
#         passenger_count,
#         trip_distance,
#         fare_amount,
#         extra,
#         mta_tax,
#         tip_amount,
#         tolls_amount,
#         total_amount,
#      FROM [nyc-tlc:green.trips_2014], [nyc-tlc:green.trips_2015], [nyc-tlc:yellow.trips]
      
  sql_table_name: "[nyc-tlc:green.trips_2015]"
  
  fields:

  - dimension_group: pickup_datetime
    type: time
    timeframes: [time, date, week, month, year, week_of_year, hour_of_day, day_of_week, minute5, minute10]
    sql: ${TABLE}.pickup_datetime

  - dimension_group: dropoff_datetime
    type: time
    timeframes: [time, date, week, month, year, week_of_year, hour_of_day, day_of_week, minute5, minute10]
    sql: ${TABLE}.dropoff_datetime
    
  - dimension: pickup_minute10_of_day
    sql:  SUBSTR(TIME(${pickup_datetime_minute10}), 0, 5)
    alias: [trips.colin]
    
  - dimension: dropoff_minute10_of_day
    sql: SUBSTR(TIME(${pickup_datetime_minute10}), 0, 5)

  - dimension: likely_destination
    type: string
    sql_case:
      LaGuardia: |
        ${TABLE}.dropoff_latitude >= 40.76 AND 
        ${TABLE}.dropoff_latitude <= 40.78 AND 
        ${TABLE}.dropoff_longitude >= -73.88 AND
        ${TABLE}.dropoff_longitude <= -73.85
      Newark: |
        ${TABLE}.dropoff_latitude >= 40.68 AND 
        ${TABLE}.dropoff_latitude <= 40.71 AND 
        ${TABLE}.dropoff_longitude >= -74.18 AND
        ${TABLE}.dropoff_longitude <= -74.16
      JFK: |
        ${TABLE}.dropoff_latitude >= 40.64 AND 
        ${TABLE}.dropoff_latitude <= 40.65 AND 
        ${TABLE}.dropoff_longitude >= -73.80 AND
        ${TABLE}.dropoff_longitude <= -73.78
      Unknown: "true"

  - dimension: likely_origin
    type: string
    sql_case:
      LaGuardia: |
        ${TABLE}.pickup_latitude >= 40.76 AND 
        ${TABLE}.pickup_latitude <= 40.78 AND 
        ${TABLE}.pickup_longitude >= -73.88 AND
        ${TABLE}.pickup_longitude <= -73.85
      Newark: |
        ${TABLE}.pickup_latitude >= 40.68 AND 
        ${TABLE}.pickup_latitude <= 40.71 AND 
        ${TABLE}.pickup_longitude >= -74.18 AND
        ${TABLE}.pickup_longitude <= -74.16
      JFK: |
        ${TABLE}.pickup_latitude >= 40.64 AND 
        ${TABLE}.pickup_latitude <= 40.65 AND 
        ${TABLE}.pickup_longitude >= -73.80 AND
        ${TABLE}.pickup_longitude <= -73.78
      Unknown: "true"
      
  - dimension: likely_airport
    type: yesno
    sql: ${likely_destination} IN ('LaGuardia', 'Newark', 'JFK') OR ${likely_origin} IN ('LaGuardia', 'Newark', 'JFK')
      
  - dimension: store_and_fwd_flag
    type: string
    sql: ${TABLE}.store_and_fwd_flag

  - dimension: rate_code
    type: int
    sql: ${TABLE}.rate_code

  - dimension: pickup_location
    type: location
    sql_latitude: ${TABLE}.pickup_latitude
    sql_longitude: ${TABLE}.pickup_longitude

  - dimension: dropoff_location
    type: location
    sql_latitude: ${TABLE}.dropoff_latitude
    sql_longitude: ${TABLE}.dropoff_longitude

  - dimension: pickup_location_rounded
    type: location
    sql_latitude: round(${TABLE}.pickup_latitude, 3)
    sql_longitude: round(${TABLE}.pickup_longitude, 3)

  - dimension: dropoff_location_rounded
    type: location
    sql_latitude: round(${TABLE}.dropoff_latitude, 3)
    sql_longitude: round(${TABLE}.dropoff_longitude, 3)
    
  - dimension: location_valid
    type: yesno
    sql: ${TABLE}.pickup_latitude != 0 AND ${TABLE}.dropoff_latitude != 0
    hidden: true

  - dimension: number_of_passengers
    type: int
    sql: ${TABLE}.passenger_count

  - dimension: trip_distance
    type: number
    sql: ${TABLE}.trip_distance

  - dimension: extra
    type: number
    sql: ${TABLE}.extra

  - dimension: mta_tax
    type: number
    sql: ${TABLE}.mta_tax

  - dimension: tip
    type: number
    sql: ${TABLE}.tip_amount
    value_format: "$#,##0.00"
    
  - dimension: tip_percentage
    type: number
    sql: (${tip} / ${fare}) * 100
    value_format: "0.00\"%\""

  - dimension: tipped
    type: yesno
    sql: ${tip} > 0

  - dimension: tolls_amount
    type: number
    sql: ${TABLE}.tolls_amount

  - dimension_group: ehail_fee
    type: time
    timeframes: [time, date, week, month]
    sql: ${TABLE}.ehail_fee

  - dimension: fare
    type: number
    sql: ${TABLE}.total_amount
    value_format: "$#,##0.00"
    
  #   MEASURES
    
  - measure: count
    type: count
    drill_fields: detail*

  - measure: total_distance
    type: sum
    sql: ${trip_distance}

  - measure: average_distance
    type: average
    sql: ${trip_distance}
    decimals: 2

  - measure: total_fare
    type: sum
    sql: ${fare}
    value_format: "$#,##0.00"

  - measure: average_fare
    type: average
    sql: ${fare}
    value_format: "$#,##0.00"

  - measure: average_passengers
    type: average
    sql: ${number_of_passengers}
    value_format: "0.0"

  - measure: average_tip
    type: average
    sql: ${tip}
    value_format: "$#,##0.00"

  - measure: total_tip
    type: sum
    sql: ${tip}
    value_format: "$#,##0.00"

  - measure: average_tip_percentage
    type: average
    sql: ${tip_percentage}
    value_format: "0.00\"%\""

  - measure: count_who_tipped
    type: count
    filters:
      tipped: Yes
      
  - measure: percent_who_tipped
    type: number
    sql: (CAST(${count_who_tipped} AS float) / CAST(${count} AS float)) * 100
    value_format: "0.00\"%\""

