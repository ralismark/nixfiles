// ==UserScript==
// @name            No Ctrl-Q
// @author          ralismark
// ==/UserScript==

(function() {
	let ctrlq = document.querySelector("key_quitApplication");
	if(ctrlq) {
		console.log("Removing ctrl-q");
		ctrlq.remove();
	}
})();
