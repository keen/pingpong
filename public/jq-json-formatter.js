/*
 * Collapsible JSON Formatter - Formatter and colorer of raw JSON code
 * 
 * jQuery Json Formatter plugin v0.1.3
 * 
 * Usage
 * -----
 * 
 * $('#target').jsonFormat('#source'); // or
 * $('#target').jsonFormat('#source', {options override defaults}); // see jf.config
 * #target {
 *     font-family: monospace;
 *     white-space: pre; // or pre-wrap // All fails without this one!
 * }
 * 
 * License
 * -------
 * 
 * Copyright (c) 2008-2009 Vladimir Bodurov
 * http://quickjsonformatter.codeplex.com/
 * 
 * Copyright (c) 2012 Redsandro - Made jQuery plugin
 * http://www.redsandro.com/
 * 
 * The MIT License (MIT)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining 
 * a copy of this software and associated documentation files (the "Software"), 
 * to deal in the Software without restriction, including without limitation 
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of the Software, and to permit persons to whom the 
 * Software is furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Software.
 */



jQuery.fn.jsonFormat = function(src, params) {
  var jf = {
    config : {
      TAB : '    ',
      depth: false,
      ImgCollapsed : "/Collapsed.gif",
      ImgExpanded : "/Expanded.gif",
      QuoteKeys : true,
      IsCollapsible : true,
      _dateObj : new Date(),
      _regexpObj : new RegExp()     
    },
    
    /**
     * Process - starts processing the JSON
     * @param json - input JSON string
     * @returns {String} html formatted JSON
     */
    Process : function(json) {
      var html = "";
      try {
        if (json == "")
          json = "\"\"";
        var obj = eval("[" + json + "]");
        html = jf.ProcessObject(obj[0], 0, false, false, false);
        return html;
      } catch (e) {
        return "JSON invalid.\n" + e.message;
      }
    },
    ProcessObject : function(obj, indent, addComma, isArray, isPropertyContent) {
      var html = "";
      var comma = (addComma) ? "<span class='Comma'>,</span> " : "";
      var type = typeof obj;
      var clpsHtml = "";
      if (jf.IsArray(obj)) {
        if (obj.length == 0) {
          html += jf.GetRow(indent, "<span class='ArrayBrace'>[ ]</span>"
              + comma, isPropertyContent);
        } else {
          clpsHtml = jf.config.IsCollapsible ? "<span><img src=\""
              + jf.config.ImgExpanded
              + "\" onClick=\"jQuery().jsonFormat(this)\" /></span><span class='collapsible'>"
              : "";
          html += jf.GetRow(indent, "<span class='ArrayBrace'>[</span>"
              + clpsHtml, isPropertyContent);
          for ( var i = 0; i < obj.length; i++) {
            html += jf.ProcessObject(obj[i], indent + 1, i < (obj.length - 1),
                true, false);
          }
          clpsHtml = jf.config.IsCollapsible ? "</span>" : "";
          html += jf.GetRow(indent, clpsHtml
              + "<span class='ArrayBrace'>]</span>" + comma);
        }
      } else if (type == 'object') {
        if (obj == null) {
          html += jf.FormatLiteral("null", "", comma, indent, isArray, "Null");
        } else if (obj.constructor == jf.config._dateObj.constructor) {
          html += jf.FormatLiteral("new Date(" + obj.getTime() + ") /*"
              + obj.toLocaleString() + "*/", "", comma, indent, isArray,
              "Date");
        } else if (obj.constructor == jf.config._regexpObj.constructor) {
          html += jf.FormatLiteral("new RegExp(" + obj + ")", "", comma, indent,
              isArray, "RegExp");
        } else {
          var numProps = 0;
          for ( var prop in obj)
            numProps++;
          if (numProps == 0) {
            html += jf.GetRow(indent, "<span class='ObjectBrace'>{ }</span>"
                + comma, isPropertyContent);
          } else {
            clpsHtml = jf.config.IsCollapsible ? "<span><img src=\""
                + jf.config.ImgExpanded
                + "\" onClick=\"jQuery().jsonFormat(this)\" /></span><span class='collapsible'>"
                : "";
            html += jf.GetRow(indent, "<span class='ObjectBrace'>{</span>"
                + clpsHtml, isPropertyContent);
            var j = 0;
            for ( var prop in obj) {
              var quote = jf.config.QuoteKeys ? "\"" : "";
              html += jf.GetRow(indent + 1, "<span class='PropertyName'>"
                  + quote
                  + prop
                  + quote
                  + "</span>: "
                  + jf.ProcessObject(obj[prop], indent + 1,
                      ++j < numProps, false, true));
            }
            clpsHtml = jf.config.IsCollapsible ? "</span>" : "";
            html += jf.GetRow(indent, clpsHtml
                + "<span class='ObjectBrace'>}</span>" + comma);
          }
        }
      } else if (type == 'number') {
        html += jf.FormatLiteral(obj, "", comma, indent, isArray, "Number");
      } else if (type == 'boolean') {
        html += jf.FormatLiteral(obj, "", comma, indent, isArray, "Boolean");
      } else if (type == 'function') {
        if (obj.constructor == jf.config._regexpObj.constructor) {
          html += jf.FormatLiteral("new RegExp(" + obj + ")", "", comma, indent,
              isArray, "RegExp");
        } else {
          obj = jf.FormatFunction(indent, obj);
          html += jf.FormatLiteral(obj, "", comma, indent, isArray, "Function");
        }
      } else if (type == 'undefined') {
        html += jf.FormatLiteral("undefined", "", comma, indent, isArray, "Null");
      } else {
        html += jf.FormatLiteral(obj.toString().split("\\").join("\\\\")
            .split('"').join('\\"'), "\"", comma, indent, isArray, "String");
      }
      return html;
    },
    IsArray : function(obj) {
      return obj && typeof obj === 'object' && typeof obj.length === 'number'
          && !(obj.propertyIsEnumerable('length'));
    }, 
    FormatLiteral : function(literal, quote, comma, indent, isArray, style) {
      if (typeof literal == 'string')
        literal = literal.split("<").join("&lt;").split(">").join("&gt;");
      var str = "<span class='" + style + "'>" + quote + literal + quote + comma
          + "</span>";
      if (isArray)
        str = jf.GetRow(indent, str);
      return str;
    },
    FormatFunction : function (indent, obj) {
      var tabs = "";
      for ( var i = 0; i < indent; i++)
        tabs += jf.config.TAB;
      var funcStrArray = obj.toString().split("\n");
      var str = "";
      for ( var i = 0; i < funcStrArray.length; i++) {
        str += ((i == 0) ? "" : tabs) + funcStrArray[i] + "\n";
      }
      return str;
    },
    GetRow : function (indent, data, isPropertyContent) {
      var tabs = "";
      for ( var i = 0; i < indent && !isPropertyContent; i++)
        tabs += jf.config.TAB;
      if (data != null && data.length > 0 && data.charAt(data.length - 1) != "\n")
        data = data + "\n";
      return tabs + data;
    },
    ExpImgClicked : function (img) {
      var container = img.parentNode.nextSibling;
      if (!container)
        return;
      var disp = "none";
      var src = jf.config.ImgCollapsed;
      if (container.style.display == "none") {
        disp = "inline";
        src = jf.config.ImgExpanded;
      }
      container.style.display = disp;
      img.src = src;
    }
  };

  // Expand clicked?
  if (src.parentNode &&
    src.parentNode.nextSibling &&
    src.parentNode.nextSibling.classList &&
    src.parentNode.nextSibling.classList.contains('collapsible'))
    jf.ExpImgClicked(src);
  
  // Optional settings to override jf.config
  jQuery.extend(jf.config, params);
  
  // each, in case for some freak reason multiple target elements are selected
  this.each(function() {
    src = jQuery(src);
    src = (src.val()) ? src.val() : src.text();
    jQuery(this).html(jf.Process(src));
  });
  
  // Daisychaining hippy love
  return this;
};
