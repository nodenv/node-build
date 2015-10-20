#!/usr/bin/env node

var force = process.argv[2] == '-f' || process.argv[2] == '--force';

var nodeVersions = require('./node_scraper.js').versions;
var iojsVersions = require('./iojs_scraper.js').versions;

console.log('Updating node versions');
nodeVersions({overwrite: force});

console.log('Updating iojs versions');
iojsVersions();
