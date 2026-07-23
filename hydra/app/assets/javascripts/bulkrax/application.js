// OVERRIDE: the gem's version uses `require_tree .`, which loads files
// from the gem's own directory on disk - it ignores our app-level
// override of bulkrax.js entirely. Requiring each file explicitly here
// (from the app's own asset paths) ensures our fixed bulkrax.js is the
// one actually loaded.

//= require bulkrax/datatables
//= require bulkrax/entries
//= require bulkrax/exporters
//= require bulkrax/importers
//= require bulkrax/navtabs
//= require bulkrax/bulkrax