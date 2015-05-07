# Test our plugin using DocPad's Testers
require('docpad').require('testers').test({
  pluginPath: __dirname+'/..'
  env: 'static'
  testerClass: 'RendererTester'
  removeWhitespace: true
})