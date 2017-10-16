'use strict';


const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();
const tableName = process.env.TABLE_NAME;

// API Gateway's Lambda proxy integration requires a
// Lambda function to return JSON in this format;
// see the Developer Guide for further details
const createResponse = (statusCode, body) => {

    return {
        statusCode: statusCode,
        body: body
    }
};

// API call to create a TODO item

exports.create = (event, context, callback) => {

    let params = {
        TableName: tableName,
        Item: JSON.parse(event.body)
    };

    let dbPut = (params) => { return dynamo.put(params).promise() };

    dbPut(params).then( (data) => {
        console.log(`CREATE ITEM SUCCEEDED FOR todo_id = ${params.Item.todo_id}`);
        callback(null, createResponse(200, `TODO item created with todo_id = ${params.Item.todo_id}\n`));
    }).catch( (err) => {
        console.log(`CREATE ITEM FAILED FOR todo_id = ${params.Item.todo_id}, WITH ERROR: ${err}`);
        callback(null, createResponse(500, err));
    });
};

// API call to retrieve all TODO items

exports.getAll = (event, context, callback) => {

    let params = {
        TableName: tableName
    };

    let dbGet = (params) => { return dynamo.scan(params).promise() };

    dbGet(params).then( (data) => {
        if (!data.Items) {
            callback(null, createResponse(404, 'ITEMS NOT FOUND\n'));
            return;
        }
        console.log(`RETRIEVED ITEMS SUCCESSFULLY WITH count = ${data.Count}`);
        callback(null, createResponse(200, JSON.stringify(data.Items) + '\n') );
    }).catch( (err) => {
        console.log(`GET ITEMS FAILED, WITH ERROR: ${err}`);
        callback(null, createResponse(500, err));
    });
};
