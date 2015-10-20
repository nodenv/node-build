#!/usr/bin/env node

var force = process.argv[2] === '-f' || process.argv[2] === '--force'

var scrape = require('./node_scraper')

console.log('Updating node versions')
scrape({
  baseUrl: 'https://nodejs.org/dist/',
  overwrite: force
})

console.log('Updating iojs versions')
scrape({
  baseUrl: 'https://iojs.org/dist/',
  prefix: 'iojs-',
  overwrite: force
})
