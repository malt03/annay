$(document).on('click', function(event) {
  if (!$(event.target).closest('.task-list-item,a').length) {
    window.webkit.messageHandlers.backgroundClicked.postMessage("");
  }
});

function update(markdown) {
    var md = window.markdownit({
        breaks: true,
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
  
    var tokens = md.parse(markdown, {});
    var map = new Map();
    var indexMap = new Map();
    tokens.filter(function(element, index, array) {
        return element.type === "inline" &&
        element.children.length > 0 &&
        element.children[0].type === "checkbox_input"
    }).forEach(function(element, index, array) {
        var key = element.children[0].attrs[1][1];
        var value = element.content;
        var index = indexMap.get(value)
        index = index == null ? 0 : index + 1
        map.set(key, [value, index]);
        indexMap.set(value, index);
    });
  
    var html = md.render(markdown).replace('$$$$scroll$$$$', '<span id="scroll"></span>');
    document.getElementById("render").innerHTML = html;
  
    $("input:checkbox").on('change', function(event) {
        var values = map.get(event.target.id);
        var json = {
            content: values[0],
            index: values[1],
            isChecked: event.target.checked
        };
        window.webkit.messageHandlers.checkboxChanged.postMessage(json);
    });
  
    var scroll = document.getElementById("scroll");
    if (scroll) { scroll.scrollIntoView(true); }
 
    return document.documentElement.outerHTML;
}

