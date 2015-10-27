var fs = require('fs')
var format = require('util').format
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
      var self = this;
      JSON.parse(responseData)
        .map(function (build) {
          return Object.assign(Object.create(Build), {
            baseUrl: options.baseUrl,
            binaries: [],
            prefix: options.prefix || '',
            version: build.version
          })
        })
        .filter(function (build) {
          return !build.fileExists || options.overwrite
        })
        .forEach(function (build) {
          getChecksumsFile(build, function(err, shasumData) {
            extractShasums(build, shasumData, writeFile)
          })
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
    return format('%s%s/SHASUMS256.txt', this.baseUrl, this.version)
  },
  get definition () {
    return format('%sinstall_package "%s" "%s"\n', this.distros, this.name, this.downloadUri)
  },
  get distros () {
    return this.binaries.map(function(binary){ return binary.definition }).join('') + (this.binaries.length ? '\n' : '')
  },
  get downloadUri () {
    return format('%s%s/%s#%s', this.baseUrl, this.version, this.package, this.shasum)
  }
}

var Binary = {
  get definition () {
    return format('distro %s "%s"\n', this.platform, this.downloadUri)
  },
  get downloadUri () {
    return format('%s%s/%s#%s', this.build.baseUrl, this.build.version, this.package, this.shasum)
  }
}



function getChecksumsFile (build, cb) {
  https.get(build.shasumFileUri, function (res) {
    if (res.statusCode !== 200) return this.emit('error', res)

    var shasumData = ''

    res
    .on('data', function (data) {
      shasumData = shasumData + data
    })
    .on('end', function () {
      cb(null, shasumData)
    })
    .on('error', this.emit.bind(this, 'error'))
  }).on('error', function (e) { console.error('Error with ', build.version, e.message) })
}

function extractShasums (build, shasumData, cb) {
  try {
    extractSourceChecksum(build, shasumData)
    extractBinaryChecksums(build, shasumData)
    cb(null, build)
  } catch (error) {
    cb(err)
  }
}

function extractSourceChecksum (build, shasumData) {
  var result = shasumData.match(/^(\w{64}) {2}(?:\.\/)?(((?:node|iojs)-v\d+\.\d+\.\d+).tar.gz)$/im)

  if (result) {
    build.shasum = result[1]
    build.package = result[2]
    build.name = result[3]
  } else {
    throw new Error("bad checksum data", shasumData)
  }
}

function extractBinaryChecksums (build, shasumData) {
  var result = shasumData.match(/^(\w{64}) {2}(?:\.\/)?((?:(?:node|iojs)-v\d+\.\d+\.\d+)-(.+).tar.gz)$/gim)
  if (!result) return

  result.forEach(function(distro) {
    var result = distro.match(/^(\w{64}) {2}(?:\.\/)?((?:(?:node|iojs)-v\d+\.\d+\.\d+)-(.+).tar.gz)$/i)
    if(!result) return
    build.binaries.push(
      Object.assign(Object.create(Binary), {
        build: build,
        shasum: result[1],
        package: result[2],
        platform: result[3]
      })
    )
  })
}

function writeFile (err, build) {
  if (err) return console.error(err)

  fs.writeFile(build.filename, build.definition, function (err) {
    if (err) return console.error(err)

    console.log(build.name + ' written')
  })
}
