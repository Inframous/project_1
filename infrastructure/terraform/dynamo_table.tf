resource "aws_dynamodb_table" "sq-proj1-table" {
    name = "TestTable"

    ## These are the default values.
    billing_mode = "PROVISIONED"
    read_capacity = 5
    write_capacity = 5

    hash_key = "TestId" // This is the attribute to be used as the hash
    attribute {
        name = "TestId" // required, The actual name of the attribute
        type = "S"  // Requierd,  attribute type (String, Number, Binary etc ..)
    
    }
    tags = {
        Name = "TestTable",
        Environment = "Proj1"
    }
}