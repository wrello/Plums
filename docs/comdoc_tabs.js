
(function () {
const docs = [
  {
    "file": "index.html",
    "name": "Plums Client",
    "order": 1
  },
  {
    "file": "plums_server_comdoc.html",
    "name": "Plums Server",
    "order": 2
  },
  {
    "file": "client_plum_comdoc.html",
    "name": "Client Plum",
    "order": 3
  },
  {
    "file": "server_plum_comdoc.html",
    "name": "Server Plum",
    "order": 4
  },
  {
    "file": "changelog_comdoc.html",
    "name": "Changelog",
    "order": 5
  }
];
let nav = document.querySelector(".nav");
if (!nav) {
    nav = document.createElement("div");
    nav.className = "nav";
    document.body.prepend(nav);
}
nav.innerHTML = "";
const pathParts = window.location.pathname.split('/');
let currentFile = pathParts.pop();

if (!currentFile || currentFile === "") {
    currentFile = "index.html";
}

docs.forEach((doc, i) => {
    const a = document.createElement("a");
    a.className = "tab";
    a.href = "./" + doc.file;
    a.textContent = doc.name;

    if (doc.file === currentFile || (currentFile === "index.html" && i === 0)) {
        a.classList.add("active");
    }

    nav.appendChild(a);
});
})();
