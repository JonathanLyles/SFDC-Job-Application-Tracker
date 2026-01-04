HttpRequest req = new HttpRequest();

req.setEndpoint('callout:JoobleNamedCredential');

req.setHeader('Content-Type', 'application/json');
String body = '{"query":"salesforce developer","location":"United States"}';
req.setBody(body);
req.setMethod('POST');
Http h = new Http();
HttpResponse res = h.send(req);
System.debug(res.getStatusCode());
