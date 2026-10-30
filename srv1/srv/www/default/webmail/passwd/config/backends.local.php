<?php
  $backends['poppassd']['disabled']= false;
  $backends['poppassd']['preferred']= true;
  $backends['poppassd']['name'] = 'Servidor';
  $backends['poppassd']['policy']['minLength'] = 8;
  $backends['poppassd']['policy']['maxLength'] = 32;
  $backends['poppassd']['policy']['minNumeric'] = 1;
  $backends['poppassd']['policy']['minAlpha'] = 1;
  $backends['poppassd']['policy']['minAlphaNum'] = 1;
/*$backends['poppassd']['policy']['minAlpha'] = 1; */
  $backends['poppassd']['policy']['minLower'] = 1;
  $backends['poppassd']['policy']['minUpper'] = 1;
