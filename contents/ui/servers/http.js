.pragma library

// Sends { method, url, headers, body } and calls cb(status, body).
// Status 0 means the server could not be reached.
function send(request, cb) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            cb(xhr.status, xhr.responseText)
        }
    }
    try {
        xhr.open(request.method, request.url)
        for (var name in request.headers) {
            xhr.setRequestHeader(name, request.headers[name])
        }
        if (request.body === null) {
            xhr.send()
        } else {
            xhr.send(request.body)
        }
    } catch (e) {
        cb(0, String(e))
    }
    return xhr
}
