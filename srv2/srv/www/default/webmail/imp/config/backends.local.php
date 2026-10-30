<?php

$servers['srv1'] = array(
    'disabled' => false,
    'name' => 'Servidor 1',
    'hostspec' => '10.0.0.1',
    'hordeauth' => false,
    'protocol' => 'imap',
    'port' => 143,
    'secure' => 'false',
    'maildomain' => '',
    'smtp' => array(
        'auth' => true,
        'localhost' => 'localhost',
        'host' => '10.0.0.1',
        'password' => null,
        'port' => 587,
        'username' => null
    ),
    'quota' => array(
        'driver' => 'imap',
        'params' => array(
            'hide_when_unlimited' => true,
            'unit' => 'MB'
        )
    ),
    // 'spam' => array(
    //      'innocent' => array(
    //          'display' => false,
    //       ),
    //     'spam' => array(
    //          'display' => false,
    //     )
    // ),
    'acl' => false,
    'cache' => false,
    'special_mboxes' => array(
         IMP_Mailbox::MBOX_DRAFTS => 'Drafts',
         IMP_Mailbox::MBOX_SENT => 'Sent',
         IMP_Mailbox::MBOX_SPAM => 'Spam',
         IMP_Mailbox::MBOX_TEMPLATES => 'Templates',
         IMP_Mailbox::MBOX_TRASH => 'Trash',
    ),
    'autocreate_special' => false,
);

$servers['srv2'] = array(
    'disabled' => false,
    'name' => 'Servidor 2',
    'hostspec' => '10.0.0.2',
    'hordeauth' => false,
    'protocol' => 'imap',
    'port' => 143,
    'secure' => 'false',
    'maildomain' => '',
    'preferred' => true,
    'smtp' => array(
        'auth' => true,
        'localhost' => 'localhost',
        'host' => '10.0.0.2',
        'password' => null,
        'port' => 587,
        'username' => null
    ),
    'quota' => array(
        'driver' => 'imap',
        'params' => array(
            'hide_when_unlimited' => true,
            'unit' => 'MB'
        )
    ),
    // 'spam' => array(
    //     'innocent' => array(
    //         'display' => false,
    //     ),
    //     'spam' => array(
    //         'display' => true,
    //         'email' => 'postmaster',
    //         'email_format' => 'digest',
    //         'null' => true,
    //         'program' => null
    //     ),
    //) ,
    'acl' => false,
    'cache' => false,
    'special_mboxes' => array(
         IMP_Mailbox::MBOX_DRAFTS => 'Drafts',
         IMP_Mailbox::MBOX_SENT => 'Sent',
         IMP_Mailbox::MBOX_SPAM => 'Spam',
         IMP_Mailbox::MBOX_TEMPLATES => 'Templates',
         IMP_Mailbox::MBOX_TRASH => 'Trash',
    ),
    'autocreate_special' => false,
);
