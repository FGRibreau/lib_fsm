-- Finite state machine tests.

---------------------- ABSTRACT STATE MACHINES -----------------------------------------------

create or replace function test.test_case_fsm_abstract_state_machine_create() returns void as $$
declare
  abstract_machine__id uuid;
begin
  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform test.assertNotNull('abstract machine not created', abstract_machine__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_update() returns void as $$
declare
  abstract_machine__id uuid;
begin
  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform lib_fsm.abstract_machine_update(abstract_machine__id, 'creation_order2', 'description');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_update_with_invalid_id() returns void as $$
declare
  abstract_machine__id uuid;
begin
  begin
    perform lib_fsm.abstract_machine_update(public.gen_random_uuid(), 'creation_order2', 'description');
  exception
    when SQLSTATE '42P01' then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_delete() returns void as $$
declare
  abstract_machine__id uuid;
begin
  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform lib_fsm.abstract_machine_delete(abstract_machine__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_delete_with_invalid_id_should_not_fail() returns void as $$
begin
  -- this operation must be idempotent
  perform lib_fsm.abstract_machine_delete(public.gen_random_uuid());
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_update_empty_name() returns void as $$
declare
  abstract_machine__id uuid;
begin
  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_machine_update(abstract_machine__id, null, '');
  exception
    when not_null_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_update_invalid_name() returns void as
$$
declare
  abstract_machine__id uuid;
begin
  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_machine_update(abstract_machine__id, 'aa', '');
  exception
    when check_violation then return;
end; perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_create_empty_name() returns void as $$
begin
  begin
    perform lib_fsm.abstract_machine_create(null, '');
  exception
    when not_null_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_machine_create_invalid_name() returns void as
$$
begin
  begin
    perform lib_fsm.abstract_machine_create('aa', '');
  exception
    when check_violation then return;
end; perform test.fail('should not go there');
end;
$$ language plpgsql;

---------------------- ABSTRACT STATES -----------------------------------------------

create or replace function test.test_case_fsm_abstract_state_create() returns void as
$$
declare
  abstract_state__id uuid;
begin
  abstract_state__id = lib_fsm.abstract_state_create(
    lib_fsm.abstract_machine_create('creation_order', null),
    'drafted',
    'command currently being draft',
    true);

  perform test.assertNotNull('function call yield a UUID', abstract_state__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_first_abstract_state_must_be_initial() returns void as
$$
declare
  abstract_machine__id uuid;
  abstract_state__id uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  begin
    -- will raise before it's the first abstract state of the abstract machine and that initial=false (default)
    perform lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', 'command currently being draft');
  exception
    when check_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_no_more_than_one_initial_state_per_abstract_machine() returns void as
$$
declare
  abstract_machine__id uuid;
  abstract_state__id uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', 'command currently being draft', 'true');
  begin
    -- will raise before it's the second abstract state with initial=true for the same abstract machine
    perform lib_fsm.abstract_state_create(abstract_machine__id, 'signed', 'command currently being draft', 'true');
  exception
    when unique_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_create_empty_name() returns void as
$$
declare
begin
  begin
    perform lib_fsm.abstract_state_create(
      lib_fsm.abstract_machine_create('creation_order', null),
      null,
      'command currently being draft', true);
  exception
    when not_null_violation then return;
  end; perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_abstract_state_create_invalid_name() returns void as
$$
declare
begin
  begin
    perform lib_fsm.abstract_state_create(
      lib_fsm.abstract_machine_create('creation_order', null),
      'aa',
      'command currently being draft', true);
  exception
    when check_violation then return;
  end; perform test.fail('should not go there');
end;
$$ language plpgsql;

---------------------- ABSTRACT TRANSITIONS --------------------------------------------

create or replace function test.test_case_fsm_transition_create() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform lib_fsm.abstract_transition_create(
    lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true),
    'submit',
    lib_fsm.abstract_state_create(abstract_machine__id, 'submitted'));
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_null_event() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_transition_create(
      lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true),
      null,
      lib_fsm.abstract_state_create(abstract_machine__id, 'submitted'));
  exception
    when not_null_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_invalid_event_name() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  perform lib_fsm.abstract_transition_create(
    lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true),
    'a',
    lib_fsm.abstract_state_create(abstract_machine__id, 'submitted'));
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_invalid_from_state() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_transition_create(
      null,
      'send',
      lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true));
  exception
    when check_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_invalid_to_state() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_transition_create(
      lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true),
      'send',
      null);
  exception
    when check_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_invalid_to_and_from_state() returns void as
$$
declare
  abstract_machine__id uuid;
begin

  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    perform lib_fsm.abstract_transition_create(
      null,
      'send',
      null);
  exception
    when check_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_when_from_to_state_mismatch() returns void as
$$
declare
  abstract_machine__id  uuid;
  abstract_machine__id2 uuid;
begin

  begin
    abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
    abstract_machine__id2 = lib_fsm.abstract_machine_create('resiliation_order', null);
    perform lib_fsm.abstract_transition_create(
      lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true),
      'submit',
      lib_fsm.abstract_state_create(abstract_machine__id2, 'submitted'));
  exception
    when check_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_with_same_from_and_to() returns void as
$$
declare
  abstract_machine__id uuid;
  abstract_state__id   uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  abstract_state__id = lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true);
  perform lib_fsm.abstract_transition_create(
    abstract_state__id,
    'submit',
    abstract_state__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_transition_create_with_same_from_and_event() returns void as
$$
declare
  abstract_machine__id uuid;
  abstract_state__id   uuid;
begin

  abstract_machine__id = lib_fsm.abstract_machine_create('creation_order', null);
  abstract_state__id = lib_fsm.abstract_state_create(abstract_machine__id, 'drafted', '', true);
  perform lib_fsm.abstract_transition_create(
    abstract_state__id,
    'submit',
    lib_fsm.abstract_state_create(abstract_machine__id, 'submitted'));

  begin
    perform lib_fsm.abstract_transition_create(
      abstract_state__id,
      'submit',
      lib_fsm.abstract_state_create(abstract_machine__id, 'sent'));
  exception
    when unique_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

---------------------- STATE MACHINES -----------------------------------------------

create or replace function test.test_case_fsm_state_machine_create_with_abstract_state__id() returns void as
$$
declare
  abstract_state__id uuid;
  state_machine__id uuid;
begin

  abstract_state__id = lib_fsm.abstract_state_create(lib_fsm.abstract_machine_create('creation_order', null), 'drafted', '', true);
  state_machine__id = lib_fsm.state_machine_create(abstract_state__id);
  perform test.assertNotNull('state machine not created', state_machine__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_create_with_abstract_state_machine__id() returns void as
$$
declare
  state_machine__id uuid;
  state record;
begin

  state_machine__id = lib_fsm.state_machine_create('081d831f-8f88-4650-aebe-4360599d4bdc'::uuid);
  perform test.assertNotNull('state machine not created', state_machine__id);
  state = lib_fsm.state_machine_get(state_machine__id);
  perform test.assertTrue(state.name = 'starting');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_create_with_invalid_id() returns void as
$$
begin

  begin
    perform lib_fsm.state_machine_create(public.gen_random_uuid());
  exception
    when foreign_key_violation then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_delete() returns void as $$
declare
  state_machine__id uuid;
begin

  state_machine__id = lib_fsm.state_machine_create(lib_fsm.abstract_state_create(lib_fsm.abstract_machine_create('creation_order', null), 'drafted', '', true));
  perform lib_fsm.state_machine_delete(state_machine__id);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_delete_with_invalid_id_should_not_fail() returns void as $$
begin
  -- this operation must be idempotent
  perform lib_fsm.state_machine_delete(public.gen_random_uuid());
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_get() returns void as
$$
declare
  state record;
begin

  state = lib_fsm.state_machine_get(
    lib_fsm.state_machine_create(
      lib_fsm.abstract_state_create(lib_fsm.abstract_machine_create('creation_order', null), 'drafted', null, true)
    )
  );

  perform test.assertTrue(state.name = 'drafted');
  perform test.assertTrue(state.description is null);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_get_unknown_machine() returns void as
$$
declare
  state record;
begin

  begin
    state = lib_fsm.state_machine_get(public.gen_random_uuid());
  exception
    -- 404
    when sqlstate '42P01' then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;

----------------------------- STATE MACHINE TRANSITION ------------------------------------

create or replace function test.test_case_fsm_state_machine_transition_check() returns void as
$$
declare
  state_machine__id uuid;
  state record;
begin

  state_machine__id = lib_fsm.state_machine_create('081d831f-8f88-4650-aebe-4360599d4bdc'::uuid);
  state = lib_fsm.state_machine_transition(state_machine__id, 'create');
  perform test.assertTrue(state.name = 'awaiting_payment');
  state = lib_fsm.state_machine_get(state_machine__id);
  perform test.assertTrue(state.name = 'awaiting_payment');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_transition_check_dry_run() returns void as
$$
declare
  state_machine__id uuid;
  state record;
begin
  -- use the state machine from fsm/_fixtures
  state_machine__id = lib_fsm.state_machine_create('081d831f-8f88-4650-aebe-4360599d4bdc'::uuid);
  state = lib_fsm.state_machine_transition(state_machine__id, 'create', true);
  perform test.assertTrue(state.name = 'awaiting_payment');
  state = lib_fsm.state_machine_get(state_machine__id);
  perform test.assertTrue(state.name = 'starting');
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_transition_invalid_event() returns void as
$$
declare
  state_machine__id uuid;
begin

  begin
    -- use the state machine from fsm/_fixtures
    state_machine__id = lib_fsm.state_machine_create('081d831f-8f88-4650-aebe-4360599d4bdc'::uuid);
    perform lib_fsm.state_machine_transition(state_machine__id, 'toto');
  exception
    when sqlstate 'P0001' then return;
  end;
  perform test.fail('should not go there');
end;
$$ language plpgsql;


create or replace function test.test_case_fsm_state_machine_get_transitions_for_unknown_state_machine() returns void as
$$
declare
  transitions jsonb;
begin
    select jsonb_agg(t) into transitions from lib_fsm.state_machine_get_next_transitions('081d831f-0000-0000-0000-4360599d4bdc') t;
    perform test.assertNull('a non-exisiting state machine should not have any transitions', transitions);
end;
$$ language plpgsql;

create or replace function test.test_case_fsm_state_machine_get_next_transitions() returns void as
$$
declare
  state_machine__id uuid;
  transitions jsonb;
begin
    -- create a state machine directly from an abstract_state_machine ("awaiting_payment")
    state_machine__id = lib_fsm.state_machine_create('081d831f-8f88-4650-aebe-4360599d4abb'::uuid);

    select jsonb_agg(t) into transitions from lib_fsm.state_machine_get_next_transitions(state_machine__id) t;

    -- transitions should old
    perform test.assertEqual(transitions, '[{"abstract_machine__id":"081d831f-8f88-4650-aebe-4360599d4bdc","from_abstract_state__id":"081d831f-8f88-4650-aebe-4360599d4abb","from_state_name":"awaiting_payment","from_state_description":null,"event":"pay","description":null,"to_abstract_state__id":"081d831f-8f88-4650-aebe-4360599d4acc","to_state_name":"awaiting_shipment","to_state_description":null},
 {"abstract_machine__id":"081d831f-8f88-4650-aebe-4360599d4bdc","from_abstract_state__id":"081d831f-8f88-4650-aebe-4360599d4abb","from_state_name":"awaiting_payment","from_state_description":null,"event":"cancel","description":null,"to_abstract_state__id":"081d831f-8f88-4650-aebe-4360599d4add","to_state_name":"canceled","to_state_description":null}]'::jsonb);
end;
$$ language plpgsql;
