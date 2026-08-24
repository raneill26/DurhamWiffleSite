/* ==========================================================================
   Durham Wiffle Ball - Player Liability Waiver

   Adapted from the Durham Wiffle Ball waiver, which is the league's own text
   and is already in use for its sister league. The activity wording has been
   changed to wiffle ball. Everything else is unchanged.

   >>> HAVE THIS REVIEWED BEFORE COLLECTING REAL SIGNATURES. <<<
   It is the softball release with the sport swapped, not a document written
   for this league.

   It is reproduced word for word on purpose. Do not reword it casually: the
   site hashes this exact text at signing time and stores the hash, so the
   league can later prove precisely what a given player agreed to. Changing a
   character changes the hash.

   If the wording is ever updated, update it in BOTH places (here and Jotform,
   if Jotform stays in use) and bump WAIVER_VERSION in assets/js/config.js so
   old and new signatures stay distinguishable.

   Note: this text has been in use by the league, which is not the same as
   having been reviewed by an attorney. See SETUP.md.
   ========================================================================== */
(function (global) {
  'use strict';

  var INTRO =
    'Players that participate in the 2026 season of Durham Wiffle Ball are required to complete ' +
    'this waiver. To participate in any way with the Durham Wiffle Ball league, the undersigned ' +
    'must acknowledge and agree to these terms.';

  /* Each of these is a separate required acknowledgement on the league's form,
     so each gets its own checkbox here too. */
  var CLAUSES = [
    'The risk of injury from the activities involved in this program is significant, including the ' +
    'potential for permanent paralysis and death, and while particular rules, equipment, and personal ' +
    'discipline may reduce this risk, the risk of serious injury does exist.',

    'I knowingly and willingly assume the risks of playing the game, both known and unknown, even if ' +
    'arising from the negligence of others, and assume full responsibility for my participation.',

    'I willingly agree to comply with the stated and customary terms and conditions for participation. ' +
    'If, however, I observe any unusual significant hazard during my presence or participation, I will ' +
    'remove myself from participation and bring such to the attention of the nearest official immediately.',

    'I, for myself and on behalf of my heirs, assigns, personal representatives and next of kin, hereby ' +
    'release and hold harmless Play NC, Inc. and their directors, officers, officials, agents, volunteers ' +
    'and/or employees, other participants, sponsoring agencies, sponsors, advertisers, and if applicable, ' +
    'owners and lessors of premises used to conduct the event ("releasees"), with respect to any and all ' +
    'injury, disability, death, or loss or damage to person or property, whether arising from the ' +
    'negligence of the releasees or otherwise, to the fullest extent permitted by law.',

    'I will not attend a game if I have had a fever, sore throat, cough, or any other respiratory ' +
    'symptoms consistent with COVID, Flu, Strep, or other respiratory illnesses within the last 5 days ' +
    'before my game. I will respect the medical concerns of others and take precautions to ensure the ' +
    'safety of my teammates and opponents.',

    'I HAVE READ THIS RELEASE OF LIABILITY AND ASSUMPTION OF RISK AGREEMENT, FULLY UNDERSTAND ITS TERMS, ' +
    'UNDERSTAND THAT I HAVE GIVEN UP SUBSTANTIAL RIGHTS BY SIGNING IT, AND SIGN IT FREELY AND VOLUNTARILY ' +
    'WITHOUT ANY INDUCEMENT.'
  ];

  var text = INTRO + '\n\n' + CLAUSES.join('\n\n');

  var html =
    '<p><strong>' + INTRO + '</strong></p>' +
    CLAUSES.map(function (c, i) {
      return '<p><span class="clause-n">' + (i + 1) + '.</span> ' + c + '</p>';
    }).join('');

  global.DS_WAIVER = {
    version: (global.DS_CONFIG && global.DS_CONFIG.WAIVER_VERSION) || 'draft',
    source: 'https://form.jotform.com/210598080020042',
    intro: INTRO,
    clauses: CLAUSES,
    text: text,
    html: html
  };
})(window);
