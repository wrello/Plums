
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

// Get the current filename. If it's empty (like at root), default to the first doc.
const pathParts = window.location.pathname.split('/');
const currentFile = pathParts.pop() || pathParts.pop(); 

docs.forEach(doc => {
    const a = document.createElement("a");
    a.className = "tab";
    a.href = "./" + doc.file;
    a.textContent = doc.name;
    
    // Normalize comparison: check if currentFile is exactly doc.file 
    // or if we are at the root and this is the first doc.
    if (currentFile === doc.file || (currentFile === "" && docs[0].file === doc.file)) {
        a.classList.add("active");
    }
    nav.appendChild(a);
});
})();
