# ### Collection Counts
# Datatables maintains counts of both the base query and filtered query reactively.
# These counts are published by the datatables publication
DataTableMixins.Collection =
  countCollection: if Meteor.isClient then new Meteor.Collection "datatable_count" else "datatable_count"

  # ##### collections [ Array ]
  # An array to track the collections initialized by datatables to prevent duplicate collection errors.
  collections: []

  # ##### DataTableComponent.getCollection( String )
  # Checks to see if a colletion already exists and returns the collection
  getCollection: ( string ) ->
    for id, collection of DataTableComponent.collections
      if collection instanceof Meteor.Collection
        if collection._name is string
          return collection
          break
    # if none of the collections match
    return undefined

  extended: ->
    @include
      # ##### prepareCollection()
      prepareCollection: ->
        if Meteor.isClient
          if @subscription
            collection = DataTableComponent.getCollection @id()
            @log "collection", collection
            if collection
              @data.collection = collection
              @log "collection:exists", collection
            else
              @data.collection = new Meteor.Collection @id()
              DataTableComponent.collections.push @data.collection
              @log "collection:created", @data.collection
            @addGetterSetter "data", "collection"
        if Meteor.isServer
          throw new Error "collection property is not defined" unless @data.collection
          @addGetterSetter "data", "collection"

      # ##### collectionName()
      collectionName: ->
        return if @collection then @collection()._name else false

      # ##### prepareCountCollection()
      prepareCountCollection: ->
        if @subscription
          unless @countCollection
            @data.countCollection = DataTableComponent.countCollection
            @addGetterSetter "data", "countCollection"

    if Meteor.isClient
      @include
        # #### `collection` Meteor Collection ( required )
        # This is the collection that houses the documents your datatable is displaying
        # and must be defined on both the client and the server.

        # ##### getCount( String )
        getCount: ( collectionName ) ->
          if @subscription
            countDoc = @countCollection().findOne( collectionName )
            if countDoc and "count" of countDoc then return countDoc.count else return 0

        # ##### getTotalCount()
        totalCount: -> @getCount @collectionName()

        # ##### getFilteredCount()
        filteredCount: -> @getCount "#{ @collectionName() }_filtered"