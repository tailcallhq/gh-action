#!/bin/bash -l
set -e

response_ok() {
  RESPONSE_CODE=$(curl --location "$1" \
  -o /dev/null \
  --header 'Content-Type: application/json' \
  --data '{"query":"\n    query IntrospectionQuery {\n      __schema {\n        \n        queryType { name }\n        mutationType { name }\n        subscriptionType { name }\n        types {\n          ...FullType\n        }\n        directives {\n          name\n          description\n          \n          locations\n          args {\n            ...InputValue\n          }\n        }\n      }\n    }\n\n    fragment FullType on __Type {\n      kind\n      name\n      description\n      \n      fields(includeDeprecated: true) {\n        name\n        description\n        args {\n          ...InputValue\n        }\n        type {\n          ...TypeRef\n        }\n        isDeprecated\n        deprecationReason\n      }\n      inputFields {\n        ...InputValue\n      }\n      interfaces {\n        ...TypeRef\n      }\n      enumValues(includeDeprecated: true) {\n        name\n        description\n        isDeprecated\n        deprecationReason\n      }\n      possibleTypes {\n        ...TypeRef\n      }\n    }\n\n    fragment InputValue on __InputValue {\n      name\n      description\n      type { ...TypeRef }\n      defaultValue\n      \n      \n    }\n\n    fragment TypeRef on __Type {\n      kind\n      name\n      ofType {\n        kind\n        name\n        ofType {\n          kind\n          name\n          ofType {\n            kind\n            name\n            ofType {\n              kind\n              name\n              ofType {\n                kind\n                name\n                ofType {\n                  kind\n                  name\n                  ofType {\n                    kind\n                    name\n                    ofType {\n                      kind\n                      name\n                      ofType {\n                        kind\n                        name\n                      }\n                    }\n                  }\n                }\n              }\n            }\n          }\n        }\n      }\n    }\n  ","operationName":"IntrospectionQuery"}' \
  -w "%{http_code}\n" -s)
  if [ "$RESPONSE_CODE" -ne 200 ]; then
    return 1
  else
    return 0
  fi
}

health_check() {
  URL1="$1"
  URL2="$URL1/graphql"
  URL3="${URL1}graphql"
  response_ok "$URL1" || response_ok "$URL2" || response_ok "$URL3"
}

health_check "$1" && echo "Health check passed." && exit 0 || echo "Health check failed." && exit 1
