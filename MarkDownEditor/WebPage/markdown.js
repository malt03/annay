function update(markdown) {
    var md = window.markdownit({
        highlight: function (str, lang) {
            if (lang && hljs.getLanguage(lang)) {
                try {
                    return '<pre class="hljs"><code>' +
                        hljs.highlight(lang, str, true).value +
                        '</code></pre>';
                } catch (__) {}
            }
            return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>';
        }
    })
        .use(window.markdownitTaskLists, {disabled: false})
        .use(window.markdownitSub)
        .use(window.markdownitSup)
        .use(window.markdownitFootnote)
        .use(window.markdownitEmoji);
    var html = md.render(markdown);
    document.getElementById("render").innerHTML = html;
  
    $("input:checkbox").on('change', function(event) {
        var json = {
            id: event.target.id,
            isChecked: event.target.checked
        };
        window.webkit.messageHandlers.checkboxChanged.postMessage(json);
    });
 
    return html;
}
