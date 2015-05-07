var Cloudant = require('cloudant');
var async = require('async');
Cloudant({url: process.env.CLOUDANT_URL}, function(err, cloudant) {
    if (err) {
        console.error(err);
        process.exit(1);
    }

    async.series([
        function(next) {
            cloudant.db.destroy('test_data', function(err) {
                // if the error is that the database doesn't exist, ignore it and carry on
                if (err && err.error != 'not_found') {
                    next(err);
                } else {
                    next();
                }
            })
        },
        cloudant.db.create.bind(cloudant.db, 'test_data'),
        function(next) {
            cloudant.use('test_data').insert({title: 'foo'}, "1", next)
        },
        function(next) {
            cloudant.use('test_data').insert({title: 'bar'}, "2", next)
        }
    ], function(err) {
        if (err){
            console.error(err);
            process.exit(1);
        }
        process.exit(0);
    });
});
