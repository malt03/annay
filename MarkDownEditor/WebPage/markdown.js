

$(document).on('click', function(event) {
    if (!$(event.target).closest('.task-list-item,a').length) {
        window.webkit.messageHandlers.backgroundClicked.postMessage("");
    }
});

function jump(anchor) {
  window.location.href = "#"+encodeURIComponent(anchor);
}

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
    .use(window.markdownitEmoji)
    .use(window.markdownitHeadingAnchor);

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

    document.getElementById("render").innerHTML = md.render(markdown);

    $("input:checkbox").on('change', function(event) {
        var values = map.get(event.target.id);
        var json = {
            content: values[0],
            index: values[1],
            isChecked: event.target.checked
        };
        window.webkit.messageHandlers.checkboxChanged.postMessage(json);
    });

    var dom = $("*:contains('$$$$scroll$$$$'):last");
    if (dom.length > 0) {
      var top = dom.offset().top;
      $(window).scrollTop(top - document.documentElement.clientHeight / 2);
    }
    document.getElementById("render").innerHTML = md.render(markdown.replace('$$$$scroll$$$$', ''));
  
    for (var img of document.getElementsByTagName('img')) {
        var url = img.getAttribute('src');
        if (new URL(url).protocol !== 'file:') { continue; }
        if (images[url]) {
            img.setAttribute('src', images[url]);
        } else {
            if (!imageTags[url]) { imageTags[url] = []; }
            imageTags[url].push(img);
            window.webkit.messageHandlers.fetchImage.postMessage(url);
        }
    }

    return document.documentElement.outerHTML;
}

var imageTags = {};
var images = {};

function updateImage(url, image) {
  console.log(url);
  console.log(imageTags[url]);
  console.log(image);
    if (imageTags[url]) {
        for (img of imageTags[url]) {
            img.setAttribute('src', image);
        }
    }
    images[url] = image;
}

function zoomIn() {
    changeScale(1);
}

function zoomOut() {
    changeScale(-1);
}

function actualSize() {
    scaleIndex = defaultScaleIndex;
    reloadScaleIndex();
}

function changeScale(indexDelta) {
    var oldScaleIndex = scaleIndex;
    scaleIndex += indexDelta;
    scaleIndex = Math.max(scaleIndex, 0);
    scaleIndex = Math.min(scaleIndex, scales.length - 1);
    if (scaleIndex == oldScaleIndex) { return; }
    reloadScaleIndex();
}

function reloadScaleIndex() {
    $('html').css('zoom', `${scales[scaleIndex]}`);
}

var defaultScaleIndex = 7;
var scaleIndex = defaultScaleIndex;

var scales = [
    0.25,
    0.33,
    0.50,
    0.67,
    0.75,
    0.80,
    0.90,
    1.00,
    1.10,
    1.25,
    1.50,
    1.75,
    2.00,
    2.50,
    3.00,
    4.00,
    5.00,
];
