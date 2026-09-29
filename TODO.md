Dividing the development into the following major chunks, and developing them in the same following order:

1. Capturing the query context and metadata
2. Logic behind computation of CDC [primary keys, IUD marking logic]
3. Movement of CDC data through Kafka
4. Storage of CDC data and its optimization

## Capturing the query context and metadata

1. We can utilize a connector-based logic, where we can write a generic wrapper around any type of connector (eg. Postgres, Spark, etc)
2. The following connector will ensure that we can only perform CRUD operations using the execute method on it. This will help us in getting the affected rows to hence, capture the query context and its metadata 
3. We can have a special type enabler called "AppendLedgerMode" in the connector, which works as follows: 
    - The data is simply inserted into the same table, with just a different temporal / primary columns
    - Based on this set of unique entity, the connector can help in finding and computing the CDC

Steps to Do:
1. Implement a Postgres connector logic
2. Implement a Spark Apache Iceberg connector logic
3. Implement the special type of "AppendLedgerMode" connector logic which needs to have a generic implementation to ensure that if the type of connectors increase, they can easily integrate with the same