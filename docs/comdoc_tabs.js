
(function () {
const docs = [
  {
    "file": "test_comdoc.html",
    "name": "Settings",
    "order": 100
  },
  {
    "file": "bigtest_comdoc.html",
    "name": "RaycastHitbox",
    "order": null
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
const currentFile = pathParts.pop() || pathParts.pop(); 

docs.forEach(doc => {
    const a = document.createElement("a");
    a.className = "tab";
    a.href = "./" + doc.file;
    a.textContent = doc.name;
    
    // Treat index.html as equivalent to the first doc
    const isIndex = currentFile === "index.html" && docs[0].file === doc.file;
    if (currentFile === doc.file || isIndex || (currentFile === "" && docs[0].file === doc.file)) {
        a.classList.add("active");
    }
    nav.appendChild(a);
});
})();
