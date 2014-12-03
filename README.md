es6-module-mapper
================

**DISCLAIMER:** This is currently a ducktaped together solution, use at your own risk.

Transforms ES6 module syntax into object references (uses a single global object map) via [recast](https://github.com/benjamn/recast) and integrates into [sprockets](https://github.com/sstephenson/sprockets) for dependency management, concatenation, etc..

## Usage

**NOTE:** This requires [nodejs](http://nodejs.org/) to be available via the `node` executable at runtime. If you're deploying with a Heroku buildpack you will need the [multi](https://github.com/heroku/heroku-buildpack-multi) buildpack.

Include the gem in your Gemfile

```ruby
# Gemfile
gem 'es6-module-mapper', :git => 'https://github.com/jvatic/es6-module-mapper.git, :branch => 'master'
```

and require it:

```ruby
require 'sprockets'
require 'es6-module-mapper'
```

You may wish to disable the `Sprockets::DirectiveProcessor` if you're not using sprockets directives:

```ruby
sprockets_environment.unregister_preprocessor(
  'application/javascript', Sprockets::DirectiveProcessor)
```

You may now use the ES6 module syntax:

```javascript
// foo.js
export function foo() {
  return "foo";
}

var FOO = "foobar";
export { FOO as FOOBAR };
```

```javascript
// bar.js
import { foo as echoFoo, FOOBAR } from "foo";
console.log(echoFoo()); // prints "foo" to the console
console.log(FOOBAR); // prints "foobar" to the console
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

