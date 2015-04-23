var Check = function() {
  var constructor = function Check(elem, checks, percentWarn, percentBad) {
    this.elem = elem;
    this.checks = checks;
    this.percentWarn = percentWarn;
    this.percentBad = percentBad;

    this.createHtml = function() {
      elem.empty();
      var responseTimes = [];
      var responseMean = 0.0, responseTotal = 0.0;

      $.each(this.checks, function(i, check) {
        responseTotal += check.request.duration
        responseTimes.push(check.request.duration);
      });

      responseMean = responseTotal / this.checks.length;

      var warnThreshold = this.percentWarn * responseMean;
      var badThreshold = this.percentBad * responseMean;
      var hasBadTime = false;
      var hasWarnTime = false;
      var hasWarnCode = false;
      var hasBadCode = false;

      $.each(this.checks, function(i, check) {
        var iconCss = "";

        if (check.request.duration > badThreshold) {
          iconCss = " error";
          hasBadTime = true;
        } else if (check.request.duration > warnThreshold) {
          iconCss = " warning";
          hasWarnTime = true;
        }

        if (check.response.status >= 300 && check.response.status < 400) {
          iconCss = iconCss || " warning";
          hasWarnCode = true;
        } else if (check.response.status >= 400 && check.response.status < 600) {
          iconCss = iconCss || " error";
          hasBadCode = true;
        }

        var checkHTML = '<div class="panel panel-default">'
            + '<div class="panel-heading" role="tab" id="heading' + i +'">'
              + '<a data-toggle="collapse" data-parent="#accordion" href="#collapse' + i +'" aria-expanded="true" aria-controls="collapse' + i +'" class="collapsed">'
                + '<h3 class="panel-title">'
                  + '<span class="status-icon' + iconCss + '" aria-hidden="true"></span>' + check.request.sent_at
                + '</h3>'
              + '</a>'
            + '</div>'
            + '<div id="collapse' + i +'" class="panel-collapse collapse" role="tabpanel" aria-labelledby="heading' + i +'">'
              + '<div class="panel-body">';
              
        for (var key in check) {
          checkHTML = checkHTML + '<div class="row">'
            + '<div class="col-md-12 json-header">'
              + key + ':'
            + '</div>'
          + '</div>';
          for (var key2 in check[key]) {
            var keyVal = check[key][key2];
            var colorCss = "";

            if (keyVal == "") {
              keyVal = "{}";
            }

            if (key == "request" && key2 == "duration") {
              if (hasWarnTime) {
                colorCss = " warning";
              } else if (hasBadTime) {
                colorCss = " error";
              }
            }

            if (key == "response" && key2 == "status") {
              if (hasWarnCode) {
                colorCss = " warning";
              } else if (hasBadCode) {
                colorCss = " error";
              }
            }

            checkHTML = checkHTML + '<div class="row">'
              + '<div class="col-xs-4 json-key">'
                + key2
              + '</div>'
              + '<div class="col-xs-8 json-value' + colorCss + '">'
                + keyVal
              + '</div>'
            + '</div>';
          }
        }
        
        checkHTML = checkHTML + '</div>'
            + '</div>'
          + '</div>';
        elem.append(checkHTML);
      });
    };
  };

  return constructor;
}();
