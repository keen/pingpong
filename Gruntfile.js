// Generated on 2014-08-27 using generator-jekyllrb 1.2.1
'use strict';

// Directory reference:
//   css: css
//   sass: _scss
//   javascript: js
//   images: img
//   fonts: fonts

module.exports = function (grunt) {
  var localConfig = grunt.file.readYAML('_config.yml');
  var privates = grunt.file.readJSON('../privates.json');

  // Show elapsed time after tasks run
  require('time-grunt')(grunt);
  // Load all Grunt tasks
  require('load-grunt-tasks')(grunt);

  grunt.initConfig({
    // Configurable paths
    project: {
      app: 'app',
      dist: 'dist'
    },
    watch: {
      concat: {
        files: ['<%= project.app %>/_scss/parts/_mixins/*.{sass,scss}'],
        tasks: ['concat']
      },
      sass: {
        files: ['<%= project.app %>/_scss/**/*.{scss,sass}'],
        tasks: ['sass:server', 'autoprefixer:server'],
        options: {
          livereload: true,
        }
      },
      autoprefixer: {
        files: ['<%= project.app %>/css/**/*.css'],
        tasks: ['copy:stageCss', 'autoprefixer:server']
      },
      jekyll: {
        files: [
          '<%= project.app %>/**/*.{html,yml,md,mkd,markdown}',
          '!<%= project.app %>/_bower_components/**/*'
        ],
        tasks: ['jekyll:server']
      },
      livereload: {
        options: {
          livereload: '<%= connect.options.livereload %>'
        },
        files: [
          '.jekyll/**/*.html',
          '.tmp/css/**/*.css',
          '{.tmp,<%= project.app %>}/<%= js %>/**/*.js',
          '<%= project.app %>/img/**/*.{gif,jpg,jpeg,png,svg,webp}'
        ]
      }
    },
    connect: {
      options: {
        port: localConfig.port_number,
        livereload: 35729,
        // change this to '0.0.0.0' to access the server from outside
        hostname: '0.0.0.0'
      },
      livereload: {
        options: {
          open: true,
          base: [
            '.tmp',
            '.jekyll',
            '<%= project.app %>'
          ]
        }
      },
      dist: {
        options: {
          open: true,
          base: [
            '<%= project.dist %>'
          ]
        }
      },
      test: {
        options: {
          base: [
            '.tmp',
            '.jekyll',
            'test',
            '<%= project.app %>'
          ]
        }
      }
    },
    clean: {
      dist: {
        files: [{
          dot: true,
          src: [
            '<%= project.dist %>/*',
            // Running Jekyll also cleans the target directory.  Exclude any
            // non-standard `keep_files` here (e.g., the generated files
            // directory from Jekyll Picture Tag).
            '!<%= project.dist %>/.git*'
          ]
        }]
      },
      server: [
        '.tmp',
        '.jekyll'
      ]
    },
    sass: {
      options: {
        bundleExec: false,
        debugInfo: false,
        lineNumbers: false,
        loadPath: 'app/_bower_components'
      },
      dist: {
        files: [{
          expand: true,
          cwd: '<%= project.app %>/_scss',
          src: '**/*.{scss,sass}',
          dest: '.tmp/css',
          ext: '.css'
        }]
      },
      server: {
        options: {
          debugInfo: true,
          lineNumbers: true
        },
        files: [{
          expand: true,
          cwd: '<%= project.app %>/_scss',
          src: '**/*.{scss,sass}',
          dest: '.tmp/css',
          ext: '.css'
        }]
      }
    },
    autoprefixer: {
      options: {
        browsers: ['last 2 versions']
      },
      dist: {
        files: [{
          expand: true,
          cwd: '<%= project.dist %>/css',
          src: '**/*.css',
          dest: '<%= project.dist %>/css'
        }]
      },
      server: {
        files: [{
          expand: true,
          cwd: '.tmp/css',
          src: '**/*.css',
          dest: '.tmp/css'
        }]
      }
    },
    jekyll: {
      options: {
        bundleExec: false,
        config: '_config.yml,_config.build.yml',
        src: '<%= project.app %>'
      },
      dist: {
        options: {
          dest: '<%= project.dist %>',
        }
      },
      server: {
        options: {
          config: '_config.yml',
          dest: '.jekyll'
        }
      },
      check: {
        options: {
          doctor: true
        }
      }
    },
    useminPrepare: {
      options: {
        dest: '<%= project.dist %>'
      },
      html: '<%= project.dist %>/index.html'
    },
    usemin: {
      html: ['<%= project.dist %>/**/*.html'],
      css: ['<%= project.dist %>/css/**/*.css'],
      options: {
        assetsDirs: '<%= project.dist %>',
        blockReplacements: {
          css: function (block) {
            return '<link rel="stylesheet" href="' + block.dest + '">';
          },
        },
      },
    },
    htmlmin: {
      dist: {
        options: {
          collapseWhitespace: true,
          collapseBooleanAttributes: true,
          removeAttributeQuotes: true,
          removeRedundantAttributes: true
        },
        files: [{
          expand: true,
          cwd: '<%= project.dist %>',
          src: '**/*.html',
          dest: '<%= project.dist %>'
        }]
      }
    },
    // Usemin adds files to concat
    concat: {
        dist: {
          src: ['<%= project.app %>/_scss/parts/_mixins/*.{sass,scss}'],
          dest: '<%= project.app %>/_scss/parts/_mixins.scss',
        }
    },
    // Usemin adds files to uglify
    uglify: {},
    // Usemin adds files to cssmin
    cssmin: {
      dist: {
        options: {
          check: 'gzip'
        }
      }
    },
    imagemin: {
      dist: {
        options: {
          progressive: true
        },
        files: [{
          expand: true,
          cwd: '<%= project.dist %>',
          src: '**/*.{jpg,jpeg,png}',
          dest: '<%= project.dist %>'
        }]
      }
    },
    svgmin: {
      dist: {
        files: [{
          expand: true,
          cwd: '<%= project.dist %>',
          src: '**/*.svg',
          dest: '<%= project.dist %>'
        }]
      }
    },
    copy: {
      dist: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= project.app %>',
          src: [
            // Jekyll processes and moves HTML and text files.
            // Usemin moves CSS and javascript inside of Usemin blocks.
            // Copy moves asset files and directories.
            'img/**/*',
            'fonts/**/*',
            // Like Jekyll, exclude files & folders prefixed with an underscore.
            '!**/_*{,/**}',
            // Explicitly add any files your site needs for distribution here.
            '_bower_components/jquery/jquery.js',
            'favicon.ico',
            'apple-touch*.png'
          ],
          dest: '<%= project.dist %>'
        }]
      },
      // Copy CSS into .tmp directory for Autoprefixer processing
      stageCss: {
        files: [{
          expand: true,
          dot: true,
          cwd: '<%= project.app %>/css',
          src: '**/*.css',
          dest: '.tmp/css'
        }]
      },
    },
    uncss: {
      options: {
        htmlroot: '.tmp',
        // 1. Ignored by PhantomJS because of the conditional IE comments?
        // 2. Ignored by UnCSS?
        // 3. Added by Google Search in 404.html
        // 4. Added by keyboardNavigation function in application.js
        ignore: [
          'b', // 3
          /\.browseHappy-.+/, // 1
          'em', // 1
          /#goog.+/, // 3
          /h[1-6](.+)?/, // 2
          /input(.+)?/, // 3
          /\.is-.+/, // 4
        ],
        report: 'min'
      },
      dist: {
        files: {'.tmp/concat/css/main.css': ['<%= project.dist %>/**/*.html']}
      }
    },
    filerev: {
      options: {
        length: 4
      },
      dist: {
        files: [{
          src: [
            '<%= project.dist %>/js/**/*.js',
            '<%= project.dist %>/css/**/*.css',
            '<%= project.dist %>/img/**/*.{gif,jpg,jpeg,png,svg,webp}',
            '<%= project.dist %>/fonts/**/*.{eot*,otf,svg,ttf,woff}'
          ]
        }]
      }
    },
    replace: {
      href: {
        src: ['<%= project.dist %>/**/*.html'],
        overwrite: true,
        replacements: [{
          from: 'href=/',
          to: 'href='+localConfig.baseurl+'/'+localConfig.name+'/'
        }]
      },
      src: {
        src: ['<%= project.dist %>/**/*.html'],
        overwrite: true,
        replacements: [{
          from: 'src=/',
          to: 'src='+localConfig.baseurl+'/'+localConfig.name+'/'
        }]
      },
      css: {
        src: ['<%= project.dist %>/**/*.css'],
        overwrite: true,
        replacements: [{
          from: 'url(/',
          to: 'url('+localConfig.baseurl+'/'+localConfig.name+'/'
        }]
      },
      space: {
        src: ['<%= project.dist %>/**/*.html'],
        overwrite: true,
        replacements: [{
          from: '><',
          to: '> <'
        }]
      },
      fix: {
        src: ['<%= project.dist %>/**/*.html'],
        overwrite: true,
        replacements: [{
          from: localConfig.baseurl+'/'+localConfig.name+'//',
          to: '//'
        },{
          from: 'debug">',
          to: '">'
        }]
      },
      cname: {
        src: ['<%= project.dist %>/CNAME'],
        overwrite: true,
        replacements: [{
          from: 'baseurl.com',
          to: localConfig.baseurl
        },{
          from: 'http://',
          to: ''
        }]
      },
    },
    buildcontrol: {
      dist: {
        options: {
          remote: 'https://github.com/archermalmo/masterplate.git',
          branch: 'gh-pages',
          commit: true,
          push: true
        }
      }
    },
    jshint: {
      options: {
        jshintrc: '.jshintrc',
        reporter: require('jshint-stylish')
      },
      all: [
        'Gruntfile.js',
        '<%= project.app %>/js/**/*.js',
        'test/spec/**/*.js'
      ]
    },
    csslint: {
      options: {
        csslintrc: '.csslintrc'
      },
      check: {
        src: [
          '<%= project.app %>/css/**/*.css'
        ]
      }
    },
    concurrent: {
      server: [
        'sass:server',
        'copy:stageCss',
        'jekyll:server'
      ],
      dist: [
        'sass:dist',
        'copy:dist'
      ]
    },
    s3: {
      options: {
        accessKeyId: privates.key,
        secretAccessKey: privates.secret,
        bucket: privates.bucket,
        access: 'public-read',
        headers: {
          // Two Year cache policy (1000 * 60 * 60 * 24 * 730)
          'Cache-Control': 'max-age=630720000, public',
          'Expires': new Date(Date.now() + 63072000000).toUTCString()
        }
      },
      build: {
        cwd: 'dist/',
        src: '**',
        dest: localConfig.name+'/'
      }
    },
    open : {
      dev : {
        path: localConfig.baseurl+'/'+localConfig.name+'/index.html',
        app: 'Google Chrome'
      }
    }
  });
  // Define Tasks
  grunt.registerTask('serve', function (target) {
    if (target === 'dist') {
      return grunt.task.run(['build', 'connect:dist:keepalive']);
    }

    grunt.task.run([
      'clean:server',
      'concurrent:server',
      'autoprefixer:server',
      'connect:livereload',
      'watch'
    ]);
  });

  grunt.registerTask('server', function () {
    grunt.log.warn('The `server` task has been deprecated. Use `grunt serve` to start a server.');
    grunt.task.run(['serve']);
  });

  // No real tests yet. Add your own.
  grunt.registerTask('test', [
  //   'clean:server',
  //   'concurrent:test',
  //   'connect:test'
  ]);

  grunt.registerTask('check', [
    'clean:server',
    'jekyll:check',
    'sass:server',
    'jshint:all',
    'csslint:check'
  ]);

  grunt.registerTask('build', [
    'clean',
    // Jekyll cleans files from the target directory, so must run first
    'jekyll:dist',
    'concurrent:dist',
    'useminPrepare',
    'concat',
    //'uncss',
    'autoprefixer:dist',
    'cssmin',
    'uglify',
    //'imagemin',
    'svgmin',
    'filerev',
    'usemin',
    'htmlmin',
    'replace'
    ]);

  grunt.registerTask('optimize', [
    // todo: need to add this task
    /*
    'useminPrepare',
    'concat',
    'uncss',
    'autoprefixer:dist',
    'cssmin',
    'uglify',
    'imagemin',
    'svgmin',
    'filerev',
    'usemin',
    'htmlmin',
    'replace' */
    ]);

  grunt.registerTask('deploy', [
    'check',
    'test',
    'build',
    'buildcontrol'
    ]);

  grunt.registerTask('aws', [
    'check',
    'test',
    'build',
    's3',
    'open'
    ]);

  grunt.registerTask('default', [
    'check',
    'test',
    'build'
  ]);
};
