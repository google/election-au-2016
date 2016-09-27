// +build appengine

package appengine_election

// appengine seems to prefer this format to "./go_backend".
// To allow us to use go get, we hide the local import of go_backend in this file and only expose
// it to the appengine build process, using the 'appengine' build constraint.
import election "go_backend"

var electionIndex = election.Index
var electionCommonHeadersMiddleware = election.CommonHeadersMiddleware
var electionNewAPIHandler = election.NewAPIHandler
