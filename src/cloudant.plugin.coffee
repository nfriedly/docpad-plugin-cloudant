# Prepare
Cloudant = require("cloudant")
{TaskGroup} = require('taskgroup')
_ = require('lodash')

# Export
module.exports = (BasePlugin) ->
  # Define
  class CloudantPlugin extends BasePlugin
    # Name
    name: 'cloudant'

    # Config
    config:
      collectionDefaults:
        cloudantConfig: {}
        relativeDirPath: null # defaults to collectionName
        extension: ".json"
        injectDocumentHelper: null
        dbName: "cloudant"
        meta: {}
        collectionName: null # defaults to dbName
        includeDesignDocs: false
      collections: []

    # DocPad v6.24.0+ Compatible
    # Configuration
    setConfig: ->
      # Prepare
      super
      config = @getConfig()
      # Adjust
      config.collections = config.collections.map (collection) ->
        return _.defaults(collection, config.collectionDefaults)
      # Chain
      @

    getBasePath: (collectionConfig) ->
      "#{collectionConfig.relativeDirPath or collectionConfig.dbName}/"


    # Fetch our documents from cloudant
    # next(err, mongoDocs)
    fetchCloudantDb: (collectionConfig, next) ->
      Cloudant collectionConfig.cloudantConfig, (err, cloudant) ->
        return next err if err
        db = cloudant.use(collectionConfig.dbName)
        db.list {include_docs:true}, (err, body) ->
          next err, body.rows.map (row) -> row.doc
      # Chain
      @

    # convert JSON doc from cloudant to DocPad-style document/file model
    # "body" of docpad doc is a JSON string of the mongo doc, meta includes all data in mongo doc
    toDocpadDoc: (collectionConfig, cloudantDoc, next) ->
      # Prepare
      docpad = @docpad
      id = cloudantDoc._id

      documentAttributes =
        data: JSON.stringify(cloudantDoc, null, '\t')
        meta: _.defaults(
          {},
          collectionConfig.meta,

          cloudantId: id
          cloudantDb: collectionConfig.dbName
          # todo check for ctime/mtime/date/etc. fields and upgrade them to Date objects (?)
          relativePath: "#{@getBasePath(collectionConfig)}#{id}#{collectionConfig.extension}"
          original: cloudantDoc, # this gives the original document without DocPad overwriting certain fields

          cloudantDoc # this puts all of the document attributes into the metadata, but some will be overwritten
        )

      # Fetch docpad doc (if it already exists in docpad db, otherwise null)
      document = docpad.getFile({cloudantId:id})


      # Existing document
      if document?
        # todo: check mtime (if available) and return now for docs that haven't changed
        document.set(documentAttributes)

        # New Document
      else
        # Create document from opts
        document = docpad.createDocument(documentAttributes)

      # Inject document helper
      collectionConfig.injectDocumentHelper?.call(@, document)

      # Load the document
      document.action 'load', (err) ->
        # Check
        return next(err, document)  if err

        # Add it to the database (with b/c compat)
        docpad.addModel?(document) or docpad.getDatabase().add(document)

        # Complete
        next(null, document)

      # Return the document
      document

    importDb: (collectionConfig, next) ->
      docpad = @docpad
      plugin = @
      plugin.fetchCloudantDb collectionConfig, (err, cloudantDocs) ->
        return next(err) if err

        docpad.log('debug', "Retrieved #{cloudantDocs.length} documents from Cloudant db #{collectionConfig.dbName}, converting to DocPad docs...")

        docTasks  = new TaskGroup({concurrency:1}).done (err) ->
          return next(err) if err
          docpad.log('debug', "Converted #{cloudantDocs.length} Coudant documents into DocPad docs...")
          next()

        isntDesign = (doc) ->
          return doc._id?.substr 0,8 isnt '_design/'

        cloudantDocs = cloudantDocs.filter(isntDesign) unless collectionConfig.includeDesignDocs

        cloudantDocs.forEach (cloudantDoc) ->
          docTasks.addTask (complete) ->
            docpad.log('debug', "Inserting #{cloudantDoc._id} into DocPad database...")
            plugin.toDocpadDoc collectionConfig, cloudantDoc, (err) ->
              return complete(err) if err
              docpad.log('debug', 'inserted')
              complete()

        docTasks.run()

    # =============================
    # Events

    # Populate Collections
    # Import MongoDB Data into the Database
    populateCollections: (opts, next) ->
      # Prepare
      plugin = @
      docpad = @docpad
      config = @getConfig()

      # Log
      docpad.log('info', "Importing Cloudant db(s) into DocPad...")

      # concurrency:0 means run all tasks simultaneously
      collectionTasks = new TaskGroup({concurrency:0}).done next

      config.collections.forEach (collectionConfig) ->
        collectionTasks.addTask (complete) ->
          plugin.importDb collectionConfig, (err) ->
            complete(err) if err

            docs = docpad.getFiles {cloudantDb: collectionConfig.dbName}, collectionConfig.sort

            collectionName = collectionConfig.collectionName or collectionConfig.dbName

            # Set the collection
            docpad.setCollection(collectionName, docs)

            docpad.log('info', "Created DocPad collection \"#{collectionName}\" with #{docs.length} documents from Cloudant")
            complete()
      collectionTasks.run()

      # Chain
      @
