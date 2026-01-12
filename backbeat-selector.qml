import QtQuick 2.0
import QtQuick.Controls 1.2
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Select Backbeat Selector"
    description: "Within the current range selection, select only onbeat (odd index) or offbeat (even index) note onsets."
    version: "1.2"
    requiresScore: true

    // *** IMPORTANT: make this a dialog plugin and give it a size ***
    pluginType: "dialog"
    width: 400
    height: 140

    // Reusable predicates
    property var pattern: ({
        onbeat:  function(n) { return (n % 2) === 1; },   // 1,3,5,...
        offbeat: function(n) { return (n % 2) === 0; }    // 2,4,6,...
    })

    // Core selection routine (your 'proc')
    function runSelection(compareFunc) {
        if (!curScore)
            return;

        var sel = curScore.selection;
        if (!sel || !sel.isRange || !sel.startSegment || !sel.endSegment) {
            console.log("Select Onbeat/Offbeat: no range selection – abort.");
            return;
        }

        var startTick  = sel.startSegment.tick;
        var endTick    = sel.endSegment.tick;
        var startStaff = sel.startStaff;
        var endStaff   = sel.endStaff;

        var nstaves = curScore.nstaves;
        if (startStaff < 0)
            startStaff = 0;
        if (endStaff >= nstaves)
            endStaff = nstaves - 1;

        console.log("Select Onbeat/Offbeat: startTick =", startTick,
                    "endTick =", endTick,
                    "staffs", startStaff, "to", endStaff);

        // Clear previous selection
        curScore.selection.clear();

        // Loop through staves in the selection
        for (var staff = startStaff; staff <= endStaff; ++staff) {
            console.log("  Staff", staff);

            // Loop through voices 0..3
            for (var voice = 0; voice < 4; ++voice) {
                var cursor = curScore.newCursor();
                cursor.staffIdx = staff;
                cursor.voice    = voice;

                // Start at SCORE_START and advance to startTick
                cursor.rewind(Cursor.SCORE_START);

                while (cursor.segment && cursor.segment.tick < startTick)
                    cursor.next();

                var onsetIndex = 0;   // 1-based index per staff+voice (no bar reset)

                while (cursor.segment && cursor.segment.tick < endTick) {
                    var el = cursor.element;

                    if (el && el.type === Element.CHORD) {
                        onsetIndex++;
                        console.log("    CHORD onsetIndex =", onsetIndex,
                                    "at tick", cursor.segment.tick);

                        if (compareFunc(onsetIndex)) {
                            var notes = el.notes;
                            if (notes && notes.length > 0) {
                                for (var i = 0; i < notes.length; ++i) {
                                    curScore.selection.select(notes[i], true);
                                }
                            }
                        }
                    }

                    cursor.next();
                }
            }
        }

        // Do *not* Qt.quit() here if you want the dialog to stay open.
    }


    // Select the lowest note of each chord (ignores onbeat/offbeat)
    function runSelectLowestNotes() {
        if (!curScore)
            return;

        var sel = curScore.selection;
        if (!sel || !sel.isRange || !sel.startSegment || !sel.endSegment) {
            console.log("Select Lowest Notes: no range selection – abort.");
            return;
        }

        var startTick  = sel.startSegment.tick;
        var endTick    = sel.endSegment.tick;
        var startStaff = sel.startStaff;
        var endStaff   = sel.endStaff;

        var nstaves = curScore.nstaves;
        if (startStaff < 0)
            startStaff = 0;
        if (endStaff >= nstaves)
            endStaff = nstaves - 1;

        curScore.selection.clear();

        for (var staff = startStaff; staff <= endStaff; ++staff) {
            for (var voice = 0; voice < 4; ++voice) {
                var cursor = curScore.newCursor();
                cursor.staffIdx = staff;
                cursor.voice    = voice;

                cursor.rewind(Cursor.SCORE_START);
                while (cursor.segment && cursor.segment.tick < startTick)
                    cursor.next();

                while (cursor.segment && cursor.segment.tick < endTick) {
                    var el = cursor.element;

                    if (el && el.type === Element.CHORD) {
                        var notes = el.notes;
                        if (notes && notes.length > 0) {
                            var lowest = notes[0];
                            for (var i = 1; i < notes.length; ++i) {
                                if (notes[i].pitch < lowest.pitch)
                                    lowest = notes[i];
                            }
                            curScore.selection.select(lowest, true);
                        }
                    }

                    cursor.next();
                }
            }
        }
    }

    // Select all notes in each chord except the lowest note (ignores onbeat/offbeat)
    function runSelectAllButLowestNotes() {
        if (!curScore)
            return;

        var sel = curScore.selection;
        if (!sel || !sel.isRange || !sel.startSegment || !sel.endSegment) {
            console.log("Select All-But-Lowest: no range selection – abort.");
            return;
        }

        var startTick  = sel.startSegment.tick;
        var endTick    = sel.endSegment.tick;
        var startStaff = sel.startStaff;
        var endStaff   = sel.endStaff;

        var nstaves = curScore.nstaves;
        if (startStaff < 0)
            startStaff = 0;
        if (endStaff >= nstaves)
            endStaff = nstaves - 1;

        curScore.selection.clear();

        for (var staff = startStaff; staff <= endStaff; ++staff) {
            for (var voice = 0; voice < 4; ++voice) {
                var cursor = curScore.newCursor();
                cursor.staffIdx = staff;
                cursor.voice    = voice;

                cursor.rewind(Cursor.SCORE_START);
                while (cursor.segment && cursor.segment.tick < startTick)
                    cursor.next();

                while (cursor.segment && cursor.segment.tick < endTick) {
                    var el = cursor.element;

                    if (el && el.type === Element.CHORD) {
                        var notes = el.notes;
                        if (notes && notes.length > 1) {
                            var lowest = notes[0];
                            for (var i = 1; i < notes.length; ++i) {
                                if (notes[i].pitch < lowest.pitch)
                                    lowest = notes[i];
                            }
                            for (var j = 0; j < notes.length; ++j) {
                                if (notes[j].pitch != lowest.pitch )
                                    curScore.selection.select(notes[j], true);
                            }
                        }
                    }

                    cursor.next();
                }
            }
        }
    }














    onRun: {
        console.log("Select Onbeat/Offbeat: UI ready.");
        // For dialog plugins, just returning here leaves the window open.
    }

    // --- UI layout ---
    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Text {
            text: "Select note onsets:"
            font.pointSize: 11
        }

        Row {
            spacing: 8

            Button {
                text: "Onbeats (1,3,5,...)"
                onClicked: {
                    runSelection(pattern.onbeat);
                }
            }

            Button {
                text: "Offbeats (2,4,6,...)"
                onClicked: {
                    runSelection(pattern.offbeat);
                }
            }
            Button {
                text: "Lowest notes"
                onClicked: {
                    runSelectLowestNotes();
                }
            }
            Button {
                text: "All but lowest notes"
                onClicked: {
                    runSelectAllButLowestNotes();
                }
            }
        }

        Button {
            text: "Close"
            onClicked: Qt.quit();
        }
    }
}

