# Read about "both-code-executed" in /020-both/999-emit-both-code-executed.coffee
APP.once "both-code-executed", ->
  APP.emit "env-specific-lib-code-executed"