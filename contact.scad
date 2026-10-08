// Personal details and the contact card built from them, shared by the card and the case.
// Values in personal.scad (gitignored) override the fictional examples.
// OpenSCAD warns "Can't open include file" until you create personal.scad.
include <personal.example.scad>
include <personal.scad>

function vcard_field(key, value) = value == "" ? "" : str(key, ":", value, "\n");

vcard = str(
    "BEGIN:VCARD\n",
    "VERSION:3.0\n",
    "N:", vcard_last_name, ";", vcard_first_name, "\n",
    "FN:", vcard_first_name, " ", vcard_last_name, "\n",
    vcard_field("ORG", vcard_org),
    vcard_field("TITLE", vcard_title),
    vcard_field("TEL", phone_text),
    vcard_field("EMAIL", email_text),
    vcard_field("URL", vcard_url),
    "END:VCARD"
);
