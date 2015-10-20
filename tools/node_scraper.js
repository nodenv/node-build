var fs = require('fs')
var https = require('https')
var path = require('path')

module.exports = function getVersions (options) {
  var distributionListingUri = options.baseUrl + 'index.json'

  https.get(distributionListingUri, function (res) {
    if (res.statusCode !== 200) return this.emit('error', res)

    var responseData = ''

    res
    .on('data', function (data) {
      responseData = responseData + data
    })
    .on('end', function () {
      JSON.parse(responseData)
        .map(function (build) {
          return Object.assign(Object.create(Build), {
            baseUrl: options.baseUrl,
            prefix: options.prefix || '',
            version: build.version
          })
        })
        .filter(function (build) {
          return !build.fileExists || options.overwrite
        })
        .forEach(function (build) {
          getShasum(build, writeFile)
        })
    })
    .on('error', this.emit.bind(this, 'error'))
  }).on('error', function (e) { console.error('Error with distribution listing', e.message) })
}

// private

var Build = {
  get basename () {
    return this.prefix + this.version.replace(/v/, '')
  },
  get filename () {
    return path.join(__dirname, '../share/node-build', this.basename)
  },
  get fileExists () {
    return fs.existsSync(this.filename)
  },
  get shasumFileUri () {
    return this.baseUrl + this.version + '/SHASUMS256.txt'
  },
  get definition () {
    return 'install_package "' + this.name + '" "' + this.downloadUri + '"\n'
  },
  get downloadUri () {
    return this.baseUrl + this.version + '/' + this.package + '#' + this.shasum
  }
}

function getShasum (build, cb) {
  https.get(build.shasumFileUri, function (res) {
    if (res.statusCode !== 200) this.emit('error', res)

    var shasumData = ''

    res
    .on('data', function (data) {
      shasumData = shasumData + data
    })
    .on('end', function () {
      var result = shasumData.match(/(\w{64}) {2}(?:\.\/)?(((?:node|iojs)-v\d+\.\d+\.\d+).tar.gz)/i)

      if (result) {
        build.shasum = result[1]
        build.package = result[2]
        build.name = result[3]

        cb(null, build)
      } else {
        cb(shasumData)
      }
    })
    .on('error', this.emit.bind(this, 'error'))
  }).on('error', function (e) { console.error('Error with ', build.version, e.message) })
}

function writeFile (err, build) {
  if (err) return console.error(err)

  fs.writeFile(build.filename, build.definition, function (err) {
    if (err) return console.error(err)

    console.log(build.name + ' written')
  })
}
