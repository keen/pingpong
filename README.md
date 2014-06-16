<p align="center">
<img align="center" src="http://f.cl.ly/items/3C2j1v2T360u1s23170P/pingpong-square.png"> 
</p>

<img src="https://travis-ci.org/keenlabs/pingpong.png?branch=master&foo=bar" alt="Pingpong Build Status">

#### Easy & Powerful HTTP Request-Response Analytics

Pingpong is an open-source monitoring framework for anything with a URL. Pingpong is especially well-suited for tracking performance and availability across families of servers.

#### How does it work?

Pingpong makes HTTP requests to URLs you configure, as frequently as once per second. Pingpong turns data about each request and response into JSON, then logs it to a configurable destination.

The default destination is Keen IO's [analytics API](https://keen.io/docs/). Keen's API supports capturing events, running queries, and creating visualizations. Pingpong ships with an HTML dashboard built on Keen that shows the following metrics:

+ HTTP response status breakdown by URL
+ Response time breakdown by URL
+ Errors and long-running requests

Pingpong automatically captures most of the data you'd want about HTTP requests and responses, but it also makes it easy to add custom properties specific to your infrastructure.

**Now, choose your own adventure:**

+ See a [live Pingpong instance](http://api-pong.herokuapp.com) that tracks the response time of popular API providers
+ Read [the inspiration](#inspiration) behind Pingpong
+ Setup and deploy your own Pingpong app (keep reading!)

#### Setup and Deployment

Pingpong is open source and easy to install. Pingpong is written in Ruby and streamlined for deployment to one or more Heroku regions. That said, you can run it on any computer with Ruby, including your local machine.

**Step 1:** Clone or fork this repository

```
$ git clone git@github.com:keenlabs/pingpong.git
$ cd pingpong
```

**Step 2:** Install dependencies

```
$ bundle install
```

If you don't have the `bundle` command, first `gem install bundler`.

**Step 3:** Add your first check

At minimum a _check_ has a name, a URL, and a frequency (how often to 'check'). Pingpong comes with an interactive rake task that makes adding checks easy. Run:

```
$ bundle exec rake checks:add
```

Answer the prompts with a site you'd like to check. We'll use Google as an example.

```
Enter a URL to check:
http://google.com

Give this check a name:
Google

How often, in seconds, to run this check? (leave blank for 60)
30

What HTTP Method? (GET or POST, leave blank for GET)
```

**Note**: Entering POST as the Method will ask you for data to be posted.

This process adds a check to a `./checks.json` file, creating it if necessary. Here's what that file looks like after we add the check:

``` json
{
  "checks": [{
    "name" : "Google",
    "url" : "http://google.com/",
    "frequency": 30
    "method": "GET",
    "data": null
  }]
}
```

You can add more checks at any time via the rake task, or simply edit the file by hand.

**Step 4:** Setup Heroku and Keen IO

This section assumes you're ok with 2 things - provisioning a Heroku app and adding the free `keen:developer` Heroku addon. That said, neither Keen nor Heroku are *required* to make Pingpong work - see the *Options and Recipes* section below for alternatives. For now, let's assume Heroku is ok.

**4a)** Create a new Heroku app and add the `keen` addon as follows:

```
$ heroku apps:create
$ heroku addons:add keen
```

Install the `heroku-config` plugin, and download your new app's environment variables:

```
$ heroku plugins:install git://github.com/ddollar/heroku-config.git
$ heroku config:pull
```

You should now have a `.env` file in your app's directory, that contains the environment variables you need to read and write data from Keen IO:

```
KEEN_PROJECT_ID=xxxxxxxxxxxxxxx
KEEN_READ_KEY=yyyyyyyyyyyyyyyyy
KEEN_WRITE_KEY=zzzzzzzzzzzzzzzz
```

Now, you're ready to start the web server locally using `foreman`, which will pick up the variables in the `.env` file. [foreman](https://github.com/ddollar/foreman) comes with the [Heroku toolbelt](https://toolbelt.heroku.com/).

```
$ foreman start
```

The Pingpong web interface should now be running on [localhost:5000](http://localhost:5000). Additionally, the checks you have configured should be running in the background of your web process. After a minute or so, you should start to see data appear on the Pingpong charts!

You're now ready to commit your changes and push your app to Heroku.

```
$ git add checks.json
$ git commit -am 'Added my checks'
$ git push heroku master
```

Once the deploy finishes, visit the URL for your application.

```
$ heroku open
```

You should again see the Pingpong dashboard. To make sure that your checks are running successfully on Heroku you can tail the output of the Heroku app:

```
$ heroku logs --tail
2014-01-31T08:22:45.191611+00:00 app[web.1]: I, [2014-01-31T08:22:45.191408 #2]  INFO -- : CheckComplete, Google, 200, 0.314894153
2014-01-31T08:22:46.100808+00:00 app[web.1]: I, [2014-01-31T08:22:46.100518 #2]  INFO -- : CheckComplete, Google, 200, 1.238122939
```

#### Check Properties

Every check requires the following properties:

+ name: for display in charts and reports
+ url: the fully qualified resource to check
+ frequency: how often to sent the request, in seconds

Additionally, checks have some optional properties:

+ method: GET or POST (defaults to GET)
+ http_username: Username for HTTP authentication
+ http_password: Password for HTTP authentication

Checks can also have any number of custom properties, which is very useful for grouping & drill-down analysis later. Place any custom properties in the `custom` namespace of the check JSON.

Here's a few example checks with custom properties:

``` json
{
  "checks": [{
    "name": "Keen IO Web",
    "url": "https://keen.io/",
    "frequency": "30",
    "custom": {
      "server_role": "web",
      "is_https": true
    }
  }, 
  {
    "name": "Keen IO API",
    "url": "https://api.keen.io/",
    "frequency": "60",
    "custom": {
      "server_role": "api",
      "is_https": true
    }
  }]
}
```

`server_role` and `is_https` are custom properties and are included each time the results of a check are recorded.

By default checks are sourced from the `checks.json` file in the project directory. However, you can implement your own `CheckSource` and specify it in `config.yml` as well.

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

#### The Pingpong dashboard

Here's a snapshot of a Pingpong [dashboard](http://api-pong.herokuapp.com) that shows the home page response time for popular API providers.

![Pingpong Dashboard](http://f.cl.ly/items/273v2H2m160l073v3l0h/Screen%20Shot%202014-02-09%20at%209.55.18%20PM.png)

This dashboard uses most of Pingpong's default visualizations, such as:

+ Average response time by check by minute, last 120 minutes
+ Count of checks, grouped by status code, last 120 minutes

It's easy to add more visualizations, and you'll get the most use out of the dashboard by adding queries that answer the specific questions you have. Or simply by breaking charts out into groups that better represent your infrastructure.

#### Adding a visualization

To add a query to the included HTML dashboard, just add a line to the `queries.json` file.

```
queries.push({
  tab: "performance",
  title: "Average Response Time By Check, Last 120 Minutes",
  chartClass: Keen.Series,
  collection: Pingpong.collection,
  queryParams: {
    analysisType: "average",
    targetProperty: "request.duration",
    timeframe: "last_120_minutes",
    interval: "minutely",
    groupBy: "check.name"
  },
  refreshEvery: 60
});

```

`tab` refers to which tab you'd like the visualization placed in. You can create new tabs in `index.haml`. `queryParams` are the parameters that will be used to make the call to Keen IO. See available options in the Keen IO [JS SDK](https://keen.io/docs) docs. `refreshEvery` describes the invterval at which the visualization will be frefrehed.

The queries object is just there for convenience. Since the full Keen IO JavaScript SDK is on the page, you can
create any other visualizations you want as well.

#### Reporting and Alerting

Pingpong uses [Pushpop](https://github.com/pushpop/pingpong.git) to provide basic alerting and reporting functionality. This functionality can easily be extended to create your own custom alerts and reports.

By default, a Pingpong instance started with `foreman start` will run Pushpop jobs. If you don't want this to be the case (for example if you run multiple geographically distributed Pingpongs and only want 1 to do the alerting), set the environment variable `SKIP_PUSHPOP=1`.

Pushpop jobs are located in the [jobs](jobs/) directory. Here's a short description of each job.

##### detect_failures_job

This job runs once per minute, querying to see if the `response.successful` property of any check is `false`. If so, it sends one email for each failed check containing the name of the check and how many times it has failed.

This job will only run if the `PUSHPOP_FROM_EMAIL` and `PUSHPOP_TO_EMAIL` environment variables are set. Likewise, the included version uses the Pushpop [sendgrid plugin](https://github.com/keenlabs/pushpop#sendgrid), so you'll need to set the requisite environment variables for that as well.

Learn more by looking at [the job](jobs/detect_failures_job.rb) and its [template](jobs/detect_failures_job.html.erb).

#### Rake tasks

Pingpong comes with a set of rake tasks to make various tasks easier. 

+ `foreman run rake checks:add` - Add a check to checks.json
+ `foreman run rake checks:run` - Run checks in an endless while loop. Useful for workers.
+ `foreman run rake checks:run_once` - Run checks once, and don't log the response. Useful for testing.
+ `foreman run rake checks:run_once[key=value]` - Run a subset of checks once, only those whose 'key' equals 'value' (e.g. name=Google)
+ `foreman run rake keen:workbench` - Print the Keen IO workbench URL for the configured project. The workbench lets you do data exploration and generates JavaScript for adding queries to your dashboard.
+ `foreman run rake keen:count` - Print counts grouped by check name
+ `foreman run rake keen:duration` - Print average durations grouped by check name
+ `foreman run rake keen:extract` - Extract 100 recent checks. Note: The Keen API stores data at full resolution, and you have access to all historical data via the [extraction resource](https://keen.io/docs/data-analysis/extractions/).
+ `foreman run rake keen:delete` - Delete the collection of checks (Use with caution! Requires `KEEN_MASTER_KEY` to be set.)

(Protip: Substitute `heroku` for `foreman` to run any of these on a Heroku dyno)


#### Additional options & recipes

##### Configuration

See `config.yml` for an idea of what can be configured with settings. Examples include timeouts, pluggable components, and environment properties. 

##### Save a URL's JSON response body

If a configured check returns JSON, you can save that JSON into the request body. This allows you to monitor and analyze not only the success or failure of web calls, but also the values they can return.

To add this to a check, simple set the `save_body` property to true.

``` json
{
  "checks": [{
    "name": "SF-Weather",
    "url": "https://api.forecast.io/forecast/95246bae8ab684243397323235f9f131/37.8267,-122.423?exclude=minutely,hourly,daily,flags",
    "frequency": 300,
    "save_body": true
  }]
}
```

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

Each major component of Pingpong is pluggable.

+ `CheckSource`: contains the list of checks to run. The default implementation is `JsonCheckSource`.
+ `CheckRunner`: schedules the checks and runs them. The default implementation is `EventmachineCheckRunner`.
+ `CheckMarshaller`: transforms a check and its result into the JSON payload to be logged. The efault implementation is `EnvironmentAwareCheckMarshaller`.
+ `CheckLogger`: logs the JSON payload from the `CheckMarshaller`. The default implementation is `KeenCheckLogger`.

Once you've written an implementation for any of these components, simply replace the previous implementation's class name in `config.yml` with name of your component.

##### Run in a worker

Pingpong can run checks in two ways:

+ a background thread inside a web process 
+ in a dedicated worker process

For smaller numbers of checks you may find the web process to be enough, but if you are doing hundreds of simultaneous checks you might consider using one or more workers.

To run Pingpong in a worker on Heroku, uncomment the `worker` line from the Procfile:

```
worker: bundle exec rake checks:run
```

Commit the change, push to Heroku, and scale workers to 1:

```
$ heroku scale worker=1
```

If you run checks in a worker, you may want to turn off checking in your web process. To do so, add the `SKIP_CHECKS` environment variable to your app's configuration:

```
$ heroku config:add SKIP_CHECKS=1
```

##### Multiple Datacenters

Running from multiple datacenters can give you a better idea of latencies across the globe. Let's say you already have a Pingpong Heroku app running in the US and you'd also like to run checks the EU.

First, create a new Heroku app in the EU:

```
$ heroku apps:create my-pingpong-app-eu --region eu
```

Next, push your Keen IO credentials up to the new app:

```
$ heroku config:push --app my-pingpong-app-eu
```

Next, set the `REGION` environment variable:

```
$ heroku config:add REGION=heroku-eu-west-1
```

As you can see in `config.yml`, Pingpong will include the `REGION` in the JSON payload for each check, making it easy to do analysis on in the future.

Now, tell git about the new Heroku EU git remote, and push your Pingpong codebase to the new app:

```
$ git remote add heroku-eu git@heroku.com:my-pingpong-app-eu.git
$ git push heroku-eu master
```

That's it! You should now have events from both datacenters going to the same Keen IO project. At this time, you might want to add a new chart to your dashboard that shows the latency from each datacenter.

##### Use a different collection name locally

Specify `KEEN_COLLECTION` as an environment variable to change the [Keen IO event collection name](https://keen.io/docs/event-data-modeling/event-data-intro/#event-collections) to which events get logged. The default is simply `checks`.

You might want to do this locally to avoid checks from your development environment intermixing with those happening in production. (Note you can also use the `environment` namespace for this too.)

You can also use `KEEN_COLLECTION` to break checks into multiple collections for any reason.

##### HTTP Authentication

Set the `HTTP_USERNAME` and `HTTP_PASSWORD` environment variables to enable HTTP authentication for the dashboard. Off by default.

#### Inspiration

Pingpong was developed in-house at Keen IO to answer a few simple, but important, questions about our web and API infrastructure:

+ Are any API servers or server processes slower than others?
+ Are any web pages or API calls slow? Are any experiencing errors?
+ Have any processes failed, or become unresponsive? Today? This month?
+ What's the latency to each DC from a client in the US? In Europe?
+ How much latency does using SSL add?

Pingpong runs all day, every day from multiple data centers around the world, helping our team understand current performance and study long term trends. To date, Pingpong has run over 19,693,312 checks in production!

While agent-based application monitoring tools like New Relic are also useful (we're big fans!), some things need to be measured from a real client exactly 1 Internet away. Additionally, few monitoring tools allow drill-downs over custom dimensions, or give the ability to create dashboards from arbitrary queries.


#### Helpful links

+ [Keen IO docs](https://keen.io)
+ [Keen IO Heroku add-on](https://addons.heroku.com/keen)

#### Event Limits

If you're using the Keen IO backend to store events, there is a limit on the number of monthly events you can send for free. Currently that limit is 50,000. The [$20/month plan](https://keen.io/pricing) doubles that limit to 100,000.

##### More Events

As an early Pingpong user you're helping us find bugs and test out new features. That's worth something, right? We think so, and we're happy to throw some extra events your way. Just [email us](mailto:team@keen.io?subject=Pingpong Events) your project ID and we'll get you hooked up.

#### Contributing

Contributions are very welcome. Here are some ideas for features:

##### Wishlist

+ More tabs & queries & visualizations on the dashboard
+ Create a table that shows slow recent checks and their full response bodies (using [extractions](https://keen.io/docs/data-analysis/extractions/))
+ Templates or builders for common `checks.json` patterns (multi-dc, many ports on same server, etc)
+ Support for more back-ends and front-ends
+ ~~Support for HTTP POST~~

Pingpong has a full set of specs. Before submitting your pull request, make sure to run them:

```
$ bundle exec rake spec
```

##### Contributors

+ Josh Dzielak - [@dzello](https://twitter.com/dzello)
+ Justin Johhson - [@elof](https://twitter.com/elof)
+ Micah Wolfe - [@micahwolfe](https://twitter.com/forzalupo)
+ Cory Watson - [@gphat](https://twitter.com/gphat)
+ Loren Siebert - [@lorensiebert](https://twitter.com/lorensiebert)

If you contribute, add your name to this list!
