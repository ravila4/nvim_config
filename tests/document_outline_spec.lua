local document = require("config.document_outline")

describe("Document outline model", function()
	it("lists Markdown headings without fenced or indented code", function()
		local tree = document.parse({
			"---",
			"# metadata",
			"---",
			"# Title",
			"~~~python",
			"# code",
			"~~~",
			"    # indented",
			"## Child",
			"text",
			"# Next",
		}, "markdown")
		assert.are.equal(2, #tree)
		assert.are.equal("Title", tree[1].name)
		assert.are.equal("Child", tree[1].children[1].name)
		assert.are.equal(9, tree[1].range["end"].line)
	end)
	it("lists only curly language chunks in Quarto", function()
		local tree = document.parse({
			"# Analysis {#sec-analysis}",
			"```python",
			"example()",
			"```",
			"```{=html}",
			"<p>raw</p>",
			"```",
			"```{python}",
			"#| label: load-data",
			"#| echo: false",
			"load()",
			"```",
			"~~~~{r}",
			"#| echo: false",
			"plot(x)",
			"~~~~",
		}, "quarto")
		assert.are.equal("Analysis", tree[1].name)
		assert.are.equal(2, #tree[1].children)
		local cell = tree[1].children[1]
		assert.are.equal("Cell 1: load-data", cell.name)
		assert.are.equal("python", cell.language)
		assert.are.same({ 8, 11 }, cell.body)
		assert.are.equal("Cell 2: plot(x)", tree[1].children[2].name)
	end)
	it("keeps complete Setext headings and unfinished chunk bounds", function()
		local tree = document.parse({ "Title", "=====", "```{python}", "x = 1" }, "quarto")
		assert.are.equal(2, tree[1].heading_end)
		assert.is_false(tree[1].children[1].closed)
		assert.are.same({ 3, 4 }, tree[1].children[1].body)
	end)
	it("skips headings in HTML comments and retains headings in fenced divs", function()
		local tree = document.parse({ "<!--", "# Hidden", "-->", "::: {.callout-note}", "## Note", ":::" }, "quarto")
		assert.are.equal(1, #tree)
		assert.are.equal("Note", tree[1].name)
	end)
	it("bounds nested div headings while preserving the enclosing document section", function()
		local tree = document.parse({
			"# Section",
			":::: {.outer}",
			"## Outer",
			"::: {.inner}",
			"### Inner",
			"inside",
			":::",
			"outer text",
			"::::",
			"after",
			"```{python}",
			"print(1)",
			"```",
			"# Next",
		}, "quarto")
		local outer = tree[1].children[1]
		assert.are.equal(12, tree[1].range["end"].line)
		assert.are.equal(7, outer.range["end"].line)
		assert.are.equal(5, outer.children[1].range["end"].line)
		assert.are.equal("Function", tree[1].children[2].kind)
	end)
	it("keeps headings of any level inside their div's parent section", function()
		local tree =
			document.parse({ "## Section", "::: note", "# Internal", "body", ":::", "after", "## Next" }, "quarto")
		assert.are.equal(2, #tree)
		assert.are.equal("Internal", tree[1].children[1].name)
		assert.are.equal(3, tree[1].children[1].range["end"].line)
		assert.are.equal(5, tree[1].range["end"].line)
	end)
	it("ignores div delimiters inside code and comments", function()
		local tree = document.parse(
			{ "::: note", "## Note", "```{python}", "# :::", '":::"', "```", "<!--", ":::", "-->", "body", ":::" },
			"quarto"
		)
		assert.are.equal(9, tree[1].range["end"].line)
		assert.are.equal(1, #tree[1].children)
	end)
end)
