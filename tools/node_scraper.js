var https = require('https');
var fs = require('fs');
var path = require('path');
var baseUrl = "https://nodejs.org/dist/";

exports.versions = function getVersions (options) {
  https.get("https://nodejs.org/dist/index.json", function(res){
    if( res.statusCode !== 200){
      return console.log('response "' + res.status + '" from http://nodejs.org/dist/')
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
          file: {
            name: filename,
            exists: fs.existsSync(filename)
          }
        }
      })
      .filter(function(build){
        return !build.file.exists || options.overwrite
      })
      .forEach(generateNodeFile)
    })
  })
}

// private

function filenameFor(version){
  return path.join(__dirname, '../share/node-build', version.substring(1))
}

function generateNodeFile( build ){
  var version = build.version
  var shaUrl = baseUrl + version + "/"
  var shaData, shaLine, installLine, parts, filePath

  if(/^(v4)/g.test(version)) {
    shaUrl += "SHASUMS256.txt";
    checksum = /[\da-zA-Z]{64}  node-v[\d]{1,2}\.[\d]{1,2}\.[\d]{1,2}.tar.gz/gi;
  } else {
    shaUrl += "SHASUMS.txt";
    checksum = /[\da-zA-Z]{40}  node-v[\d]{1,2}\.[\d]{1,2}\.[\d]{1,2}.tar.gz/gi;
  }

  https.get(shaUrl, function(res){
    if( res.statusCode !== 200){
      return console.log('response "' + res.status + '" from ' + shaUrl)
    }

    shaData = ''

    res.on('data', function(data){
      shaData = shaData + data
    });

    res.on('end', function(){
      shaLine = shaData.match(checksum)

      if(shaLine && shaLine.length){
        parts = shaLine[0].split('  ')
        //this is gnarly, oh well
        //install_package "node-v0.10.0" "http://nodejs.org/dist/v0.10.0/node-v0.10.0.tar.gz#7321266347dc1c47ed2186e7d61752795ce8a0ef"
        installLine = 'Xinstall_package "node-' + version + '" "' + baseUrl + version + '/' + parts[1] + '#'+parts[0]+'"\n'
        filePath = path.join(__dirname, '../share/node-build', version.substring(1))
        fs.writeFile(filePath, installLine, function(err){
          if(err)
            console.log(err)
          else
            console.log( version.substring(1) + ' file writen')
        })
      }
    })
  })
};
