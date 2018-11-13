url = "http://localhost:32769"

# Elastix.Index.create(url, "document", %{})
# |> IO.inspect

mapping = %{
  properties: %{
    id: %{type: "int"},
    realm_id: %{type: "int"},
    ean: %{type: "text"},
    title: %{type: "text"},
    subtitle: %{type: "text"},
    abstract: %{type: "text"},
    fulltext: %{type: "text"},
    language: %{type: "keyword"},
    bisac: %{
      properties: %{
        code: "keyword",
        name: "text"
      }
    },
    on_sale_date: %{type: "date"}
  }
}

data = %{
  id: 1387,
  realm_id: 1,
  ean: "9783",
  title: "Jugendliche",
  subtitle: "Internet Communities",
  on_sale_date: "2018-01-06",
  bisac: ["FIC00001", "NAT010101"]
}

#Elastix.Mapping.put(url, "document", "mappung", mapping)
#|> IO.inspect

#Elastix.Document.index_new(url, "document", "docum", data)
#|> IO.inspect

#Elastix.Document.index(url, "document", "docum", 1387, data)
#|> IO.inspect

#Elastix.Document.get(url, "document", "docum", 1387)
#|> IO.inspect

Elastix.Search.search(url, "document", ["docum"], %{
    query: %{
        match: %{
            title: %{
                query: "jugendlich",
                fuzziness: 5
            }
        }
    }
})
|> IO.inspect
