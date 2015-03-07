var recast = require('recast');
var Promise = require('es6-promise').Promise;

function sendEvent(name, data) {
	var str = "event: "+ name +"\n";
	str += "data: "+ JSON.stringify(data) +"\n";
	console.log(str);
}

function runTransformer(data) {
	var b = recast.types.builders;
	var moduleName = data.moduleName;
	var modulesGlobalVarName = data.modulesGlobalVarName;
	var modulesLocalVarName = data.modulesLocalVarName;
	try {
		var ast = recast.parse(data.body);
	} catch (e) {
		console.error(e);
		console.error(data);
		return Promise.resolve({
			body: data.body
		});
	}
	var imports = {};

	var prevPromise = Promise.resolve();
	return Promise.all(ast.program.body.map(function (node, index) {
		switch (node.type) {
			case "ImportDeclaration":
				imports[node.source.value] = {
					specifiers: node.specifiers
				};
				var moduleLookupName = node.source.value;
				return prevPromise = prevPromise.then(function () {
					return new Promise(function (resolve) {
						resolve((function (moduleName) {
							var thisModule = b.memberExpression(b.identifier(modulesLocalVarName), b.literal(moduleName), true);
							ast.program.body[index] = b.variableDeclaration("var", node.specifiers.map(function (sp) {
									var name;
									if (sp.name) {
										name = sp.name.name;
									} else {
										name = sp.id.name;
									}
									return b.variableDeclarator(b.identifier(name), b.logicalExpression(
										"||",
										b.memberExpression(thisModule, b.identifier(sp.id.name), false),
										b.memberExpression(thisModule, b.identifier("default"), false)
									));
								}));
						})(data.imports[moduleLookupName]));
					});
				});

			case "ExportDeclaration":
				var name;
				if (node.default) {
					name = "default";
				}
				if (!node.declaration) {
					// TODO: Find a better way of combining expressions
					ast.program.body[index] = b.ifStatement(b.literal(true), b.blockStatement(node.specifiers.map(function (specifier) {
						var name = specifier.name ? specifier.name.name : specifier.id.name;
						return b.expressionStatement(b.assignmentExpression(
								"=", b.identifier(modulesLocalVarName+'["'+ moduleName +'"].'+ name),
								b.identifier(specifier.id.name)
							));
					})));
					return Promise.resolve(node);
				}
				var expression;
				switch (node.declaration.type) {
					case "FunctionDeclaration":
						var fn = node.declaration;
						if (!name) {
							name = fn.id.name;
						}
						expression = b.functionExpression(null, fn.params, fn.body);
					break;

					case "Identifier":
						if (!name) {
							name = node.declaration.name;
						}
						expression = b.identifier(node.declaration.name);
					break;

					default:
						if (node.declaration.type.match(/Expression$/)) {
							if (!name) {
								name = node.declaration.id.name;
							}
							expression = node.declaration;
						} else {
							console.error('Unsupported export declaration: ', node);
							return Promise.reject();
						}
				}
				ast.program.body[index] = b.expressionStatement(b.assignmentExpression(
						"=", b.identifier(modulesLocalVarName+'["'+ moduleName +'"].'+ name),
						expression
					));
			break;
		}
		return Promise.resolve(node);
	})).then(function () {

		var _body = [b.expressionStatement(b.assignmentExpression(
			"=", b.identifier(modulesLocalVarName+'["'+ moduleName +'"]'),
			b.objectExpression([])
		))].concat(ast.program.body);
		ast.program.body = [
			b.expressionStatement(
				b.callExpression(
					b.functionExpression(
						null, // Anonymize the function expression.
						[b.identifier(modulesLocalVarName)],
						b.blockStatement(
							[b.expressionStatement(b.literal("use strict"))].concat(_body)
						)
					), [b.identifier(modulesGlobalVarName +' = '+ modulesGlobalVarName +' || {}')]))
		];
		return Promise.resolve({
			body: recast.print(ast).code
		});
	}).catch(function (err) {
		console.error(err);
		return Promise.resolve({
			body: data.body
		});
	});
}

function handleEvent(event) {
	switch (event.name) {
		case "end":
			return Promise.resolve({
				name: "end",
				data: {},
				shouldClose: true
			});

		case "transform":
			return runTransformer(event.data).then(function (res) {
				return Promise.resolve({
					name: "transformed",
					data: res
				});
			});

		default:
			return Promise.resolve({
				name: "echo",
				data: event.data
			});
	}
}

function handleInput(body) {
	var parts = body.split("\n");
	var name = parts[0].replace(/^event:\s+/, '');
	var data = parts[1].replace(/^data:\s+/, '');
	handleEvent({
		name: name,
		data: JSON.parse(data)
	}).then(function (responseEvent) {
		if (responseEvent) {
			sendEvent(responseEvent.name, responseEvent.data);
			if (responseEvent.shouldClose) {
				process.exit(0);
			}
		}
	}).catch(function (err) {
		console.error(err);
	});
}

process.stdin.setEncoding('utf8');

var inputData = "";
process.stdin.on('readable', function () {
	var chunk = process.stdin.read();
	inputData += chunk;
	if (inputData.slice(inputData.length-2) === "\n\n") {
		inputData.split("\n\n").forEach(function (eventStr) {
			if (eventStr === "") {
				return;
			}
			handleInput(eventStr);
		});
		inputData = "";
	}
});

sendEvent("start", {});
