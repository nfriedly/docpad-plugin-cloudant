// this script is run by the mongodb shell

// setup our connection & grab the database
//conn = new Mongo();
//db = conn.getDB("docpad_plugin_mongodb_test");
db = connect("docpad_plugin_mongodb_test");

// clear our any leftover content
db.testData.drop();

// insert our test content
db.testData.insert({_id: 1, title: "foo"});
db.testData.insert({_id: 2, title: "bar"});