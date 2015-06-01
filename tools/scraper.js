#!/usr/bin/env node

var nodeVersions = require('./node_scraper.js').versions;
var iojsVersions = require('./iojs_scraper.js').versions;

console.log('Updating node versions');
nodeVersions();

console.log('Updating iojs versions');
iojsVersions();
