var https = require('https');
var fs = require('fs');
var path = require('path');

var baseUrl = "https://nodejs.org/dist/";
var distributionListingUri = baseUrl + 'index.json'

exports.versions = function getVersions (options) {
  https.get(distributionListingUri, function(res){
    if( res.statusCode !== 200){
      return console.error('response "' + res.statusCode + '" from ' + distributionListingUri)
    }

    var responseData = ""

    res.on('data', function( data ){
      responseData = responseData + data
    })

    res.on('end', function(){
      JSON.parse(responseData)
      .map(function(build){
        var filename = filenameFor(build.version)
        return {
          version: build.version,
          shasumFileUri: shasumFileUri(build.version),
          file: {
            name: filename,
            exists: fs.existsSync(filename)
          }
        }
      })
      .filter(function(build){
        return !build.file.exists || options.overwrite
      })
      .forEach(function(build){
        getShasum(build, writeFile)
      })
    })
  })
}

// private

function filenameFor(version){
  return path.join(__dirname, '../share/node-build', version.substring(1))
}

function shasumFileUri(version){
  return baseUrl + version + "/SHASUMS256.txt"
}

function downloadUri(build){
  return baseUrl + build.version + '/' + build.package + '#' + build.shasum
}

function fileContentsFor(build){
    //    //install_package "node-v0.10.0" "http://nodejs.org/dist/v0.10.0/node-v0.10.0.tar.gz#7321266347dc1c47ed2186e7d61752795ce8a0ef"
  return 'install_package "node-' + build.version + '" "' + downloadUri(build) + '"\n'
}

function getShasum(build, cb){
  https.get(build.shasumFileUri, function(res){
    if(res.statusCode !== 200){
      return cb('response "' + res.statusCode + '" from ' + build.shasumFileUri)
    }

    var shasumData = ''

    res.on('data', function(data){
      shasumData = shasumData + data
    });

    res.on('end', function(){
      var result = shasumData.match(/(\w{64})  (?:\.\/)?(node-v\d+\.\d+\.\d+.tar.gz)/i)

      if(result) {
        build.shasum = result[1]
        build.package = result[2]

        cb(null, build)
      } else {
        cb(shasumData)
      }
    })
  })

    //    //install_package "node-v0.10.0" "http://nodejs.org/dist/v0.10.0/node-v0.10.0.tar.gz#7321266347dc1c47ed2186e7d61752795ce8a0ef"
    //    installLine = 'Xinstall_package "node-' + version + '" "' + baseUrl + version + '/' + parts[1] + '#'+parts[0]+'"\n'
    //    filePath = path.join(__dirname, '../share/node-build', version.substring(1))
}

function writeFile(err, build){
  if(err) return console.error(err)

  fs.writeFile(filenameFor(build.version), fileContentsFor(build), function(err){
    if(err) return console.error(err)

    console.log( build.version + ' file writen')
  })
}
