<p align="center">
<img align="center" src="http://f.cl.ly/items/3C2j1v2T360u1s23170P/pingpong-square.png"> 
</p>

<img src="https://travis-ci.org/keen/pingpong.png?branch=master&foo=bar" alt="Pingpong Build Status">

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

#### Easy & Powerful HTTP Request-Response Analytics

Track real-time performance and availability across multiple API servers to see the what, when, and how behind your system performance. So you can understand why.

![Pingpong Graph](http://keen.github.io/pingpong/img/chart_02_new.png)

#### How Does It Work?

+ Pingpong makes HTTP requests to URLs you configure, as frequently as once per minute. Pingpong turns data about each request and response into JSON.
+ The default destination is Keen IO's [analytics API](https://keen.io/docs/). Keen's API supports capturing events, running queries, and creating visualizations.
+ Pingpong ships with an HTML dashboard built on Keen that shows the following metrics:
  + HTTP response status breakdown by URL
  + Response time breakdown by URL
  + Errors and long-running requests
+ Pingpong automatically captures most of the data you'd want about HTTP requests and responses, but it also makes it easy to add custom properties specific to your infrastructure.

**Now, choose your own adventure:**

+ Deploy straight to Heroku
+ Setup and deploy your own Pingpong app (keep reading!)

#### Setup & Deployment

Pingpong is open source and easy to install. Pingpong is written in Ruby and streamlined for deployment to one or more Heroku regions. That said, you can run it on any computer with Ruby, including your local machine.

**Step 1:** Clone or fork this repository

```
$ git clone git@github.com:keen/pingpong.git
$ cd pingpong
```

**Step 2:** Install dependencies

```
$ bundle install
```

If you don't have the `bundle` command, first `gem install bundler`.

**Step 3:** Set up database tables

```
$ mkdir -p db/migrate
$ thor pingpong:setup
```

This will create one migration for two tables, `checks` and `incidents`, then run the migration. The default database driver is postgresql, but you can configure something else in `database.yml`.

You will need to have a running postgres database!

**Step 4:** Set up the environment variables

You'll need to sign up for a free [Keen IO](https://keen.io) account. Once your account is set up, create a new project.

You'll need to grab the `project id`, `read key`, and `write key`. Add these to a root level file called `.env`. It should look like this:

```
KEEN_PROJECT_ID=xxxxxxxxxxxxxxx
KEEN_READ_KEY=yyyyyyyyyyyyyyyyy
KEEN_WRITE_KEY=zzzzzzzzzzzzzzzz
```

Now you're ready to start the web server locally using `foreman`, which will pick up the variables in the `.env` file. [foreman](https://github.com/ddollar/foreman) comes with the [Heroku toolbelt](https://toolbelt.heroku.com/).

```
$ foreman start
```

The Pingpong web interface should now be running on [localhost:5000](http://localhost:5000). Click on the button to create a new check, and then within a few minutes, you'll see the check data populating the charts.

#### Check Properties

Every check requires the following properties:

+ name: for display in charts and reports
+ url: the fully qualified resource to check
+ frequency: how often to sent the request, in minutes

Additionally, checks have some optional properties:

+ method: GET, POST, or DELETE (defaults to GET)
+ http_username: Username for HTTP authentication
+ http_password: Password for HTTP authentication

Checks can also have any number of custom properties, which is very useful for grouping & drill-down analysis later. Place any custom properties in the `custom` field.

#### HTTP Request & Response as an Event

Each time a check is run, a JSON object describing the check, request, and response is logged via a `CheckLogger` component, defaulting to `KeenCheckLogger`. Here's an example event payload:

``` json
{
  "check": {
    "name": "Keen IO Web",
    "url": "https://keen.io",
    "frequency": 5,
    "custom": {
      "server_role": "https",
      "is_https": true
    }
  },
  "environment": {
    "rack_env": "production",
    "region": "heroku_us_east",
    "location": "Virginia, US"
  },
  "request": {
    "sent_at": "2013-10-12T00:00:00.000Z",
    "duration": 0.432
  },
  "response": {
    "successful": true,
    "timed_out": false,
    "status": 200,
    "server": "TornadoServer/3.1",
    "http_status": 200,
    "http_reason": "OK",
    "http_version": "1.1",
    "content_type": "text/html",
    "content_length": 175,
    "date": "Wed, 16 Apr 2014 17:39:01 GMT"
  }
}
```

Here's a breakdown of the major sections:

+ check: properties describing the check, including any custom properties
+ environment: properties describing where the check was made from (useful when you are running Pingpong instances across multiple datacenters)
+ request: information about the HTTP request that was sent
+ response: information about the HTTP response that was recorded

`response.timed_out` and `response.successful` are helper properties. `response.successful` is true if the request did not timeout and the response
status is between 100 and 399.

It's easy to add more fields to the `environment` section in `config.yml`, or implement a `CheckMarshaller` component that translates HTTP response fields to properties in a different way.

Capturing all of these fields makes it possible to perform powerful grouping and filtering during analysis.

#### Reporting and Alerting

Pingpong uses [Pushpop](https://github.com/pushpop/pingpong.git) to provide basic alerting and reporting functionality. This functionality can easily be extended to create your own custom alerts and reports.

#### Additional Options & Recipes

##### Configuration

See `config.yml` for an idea of what can be configured with settings. Examples include timeouts, pluggable components, and environment properties. 

##### Save a URL's JSON Response Body

If a configured check returns JSON, you can save that JSON into the request body. This allows you to monitor and analyze not only the success or failure of web calls, but also the values they can return.

To save the body, select true when creating a new check.

This example grabs the weather from the [Forecast.io API](https://developer.forecast.io/) as JSON. The weather data will be merged into the response body under the key `response.body`. Here's an example check response event (some fields omitted for clarity):

``` json
{ 
  "response": {
    "body": {
      "latitude": 37.8267,
      "longitude": -122.423,
      "timezone": "America/Los_Angeles",
      "currently": {
        "temperature": 56.78,
        "summary": "Overcast",
        "icon": "cloudy"
      }
    }
  }
}
```

Now you can visualize temperature over time by using `response.body.currently.temperature` as the target property for analysis!

*Note*: The `Content-Type` header of the check's response must contain `application/json` for it to be saved. Otherwise a warning will be logged.

*Note #2*: To avoid hitting Keen IO limits on the number of properties per event and per collection across all events, JSON response bodies should ideally be small and/or consistent.

##### Pluggability

Each major component of Pingpong is pluggable:

+ Checks get run by a [pushpop](https://github.com/pushpop-project/pushpop) job in `jobs/run_checks_job.rb`
+ `CheckMarshaller`: transforms a check and its result into the JSON payload to be logged. The efault implementation is `EnvironmentAwareCheckMarshaller`.
+ `CheckLogger`: logs the JSON payload from the `CheckMarshaller`. The default implementation is `KeenCheckLogger`.

Once you've written an implementation for any of these components, simply replace the previous implementation's class name in `config.yml` with name of your component.

##### HTTP Authentication

Set the `HTTP_USERNAME` and `HTTP_PASSWORD` environment variables to enable HTTP authentication for the dashboard. Off by default.

#### Custom Headers

Set the `headers` property of a check to a hash of headers you'd like included with the request. For example:

``` json
{
  "checks": [
    {
      "name": "JSON API Check",
      "url": "http://example.com/api",
      "frequency": 5,
      "headers": { "Accept": "application/json" },
      "method": "GET"
    }
  ]
}
```
#### Inspiration

Pingpong was developed in-house at Keen IO to answer a few simple, but important questions about our web and API infrastructure:

+ Are any API servers or server processes slower than others?
+ Are any web pages or API calls slow? Are any experiencing errors?
+ Have any processes failed, or become unresponsive? Today? This month?
+ What's the latency to each DC from a client in the US? In Europe?
+ How much latency does using SSL add?

Pingpong runs all day, every day from multiple data centers around the world, helping our team understand current performance and study long-term trends. To date, Pingpong has run over 19,693,312 checks in production!

While agent-based application monitoring tools like New Relic are also useful (we're big fans!), some things need to be measured from a real client exactly 1 Internet away. Additionally, few monitoring tools allow drill-downs over custom dimensions, or provide the ability to create dashboards from arbitrary queries.


#### Helpful Links

+ [Keen IO docs](https://keen.io)
+ [Keen IO Heroku add-on](https://addons.heroku.com/keen)

#### Event Limits

If you're using the Keen IO backend to store events, there's a limit on the number of monthly events you can send for free. Currently, that limit is 50,000 events/month. The [$20/month plan](https://keen.io/pricing) doubles that limit to 100,000.

##### More Events

As an early Pingpong user, you're helping us find bugs and test out new features. That's worth something, right? We think so, and we're happy to throw some extra events your way. Just [email us](mailto:team@keen.io?subject=Pingpong Events) your project ID and we'll get you hooked up.

#### Contributing

Contributions are very welcome. Here are some ideas for new features:

##### Wish List

+ More tabs and queries and visualizations on the dashboard
+ More default alerts
+ Deploy instructions for multiple platforms
+ Ability to merge multiple data centers into one set of graphs
+ Support for more back-ends and front-ends
+ ~~Support for HTTP POST~~

Pingpong has a full set of specs. Before submitting your pull request, make sure to run them:

```
$ bundle exec rake spec
```

##### Contributors

+ Josh Dzielak - [@dzello](https://github.com/dzello)
+ Justin Johnson - [@elof](https://github.com/elof)
+ Micah Wolfe - [@micahwolfe](https://github.com/forzalupo)
+ Cory Watson - [@gphat](https://github.com/gphat)
+ Loren Siebert - [@lorensiebert](https://github.com/loren)
+ Alex Kleissner - [@hex337](https://github.com/hex337)
+ Mariano Vallés - [@zucaritask](https://github.com/zucaritask)

If you contribute, add your name to this list!
