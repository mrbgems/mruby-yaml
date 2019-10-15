
#include <stdio.h>
#include <string.h>
#include <yaml.h>
#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/string.h>
#include <mruby/array.h>
#include <mruby/hash.h>
#include <stdint.h>
#include <errno.h>
#include <ctype.h>

#if defined(_MSC_VER)
#define strtoll _strtoi64
#endif

#define streql(a, b) (strcmp(a, b) == 0)

#ifndef MRUBY_YAML_NULL
#  define MRUBY_YAML_NULL 1
#endif
#ifndef MRUBY_YAML_BOOLEAN_ON
#  define MRUBY_YAML_BOOLEAN_ON 1
#endif
#ifndef MRUBY_YAML_BOOLEAN_YES
#  define MRUBY_YAML_BOOLEAN_YES 1
#endif
#ifndef MRUBY_YAML_BOOLEAN_SHORTHAND_YES
#  define MRUBY_YAML_BOOLEAN_SHORTHAND_YES 0
#endif
#ifndef MRUBY_YAML_BOOLEAN_OFF
#  define MRUBY_YAML_BOOLEAN_OFF 1
#endif
#ifndef MRUBY_YAML_BOOLEAN_NO
#  define MRUBY_YAML_BOOLEAN_NO 1
#endif
#ifndef MRUBY_YAML_BOOLEAN_SHORTHAND_NO
#  define MRUBY_YAML_BOOLEAN_SHORTHAND_NO 0
#endif

void mrb_mruby_yaml_gem_init(mrb_state *mrb);
void mrb_mruby_yaml_gem_final(mrb_state *mrb);

typedef struct yaml_write_data_t
{
  mrb_state *mrb;
  mrb_value str;
} yaml_write_data_t;

int yaml_write_handler(void *data, unsigned char *buffer, size_t size);
static void raise_parser_problem(mrb_state *mrb, yaml_parser_t *parser);

static mrb_value node_to_value_with_aliases(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node, int use_scalar_aliases);
static mrb_value node_to_value_key(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node);
static mrb_value node_to_value(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node);
static int value_to_node(mrb_state *mrb,
  yaml_document_t *document, mrb_value value);


mrb_value
mrb_yaml_load(mrb_state *mrb, mrb_value self)
{
  yaml_parser_t parser;
  yaml_document_t document;
  yaml_node_t *root;

  mrb_value yaml_str;
  mrb_value result;

  /* Extract arguments */
  mrb_get_args(mrb, "S", &yaml_str);

  /* Initialize the YAML parser */
  yaml_parser_initialize(&parser);
  yaml_parser_set_input_string(&parser,
    (unsigned char *) RSTRING_PTR(yaml_str), RSTRING_LEN(yaml_str));

  /* Load the document */
  yaml_parser_load(&parser, &document);

  /* Error handling */
  if (parser.error != YAML_NO_ERROR)
  {
    raise_parser_problem(mrb, &parser);
    return mrb_nil_value();
  }

  /* Convert the root node to an MRuby value */
  root = yaml_document_get_root_node(&document);
  result = node_to_value(mrb, &document, root);

  /* Clean up */
  yaml_document_delete(&document);
  yaml_parser_delete(&parser);

  return result;
}


mrb_value
mrb_yaml_dump(mrb_state *mrb, mrb_value self)
{
  yaml_emitter_t emitter;
  yaml_document_t document;

  mrb_value root;
  yaml_write_data_t write_data;

  /* Extract arguments */
  mrb_get_args(mrb, "o", &root);

  /* Build the document */
  yaml_document_initialize(&document, NULL, NULL, NULL, 0, 1);
  value_to_node(mrb, &document, root);

  /* Initialize the emitter */
  yaml_emitter_initialize(&emitter);

  write_data.mrb = mrb;
  write_data.str = mrb_str_new(mrb, NULL, 0);
  yaml_emitter_set_output(&emitter, &yaml_write_handler, &write_data);

  /* Dump the document */
  yaml_emitter_open(&emitter);
  yaml_emitter_dump(&emitter, &document);
  yaml_emitter_close(&emitter);

  /* Clean up */
  yaml_emitter_delete(&emitter);
  yaml_document_delete(&document);

  return write_data.str;
}


int yaml_write_handler(void *data, unsigned char *buffer, size_t size)
{
  yaml_write_data_t *write_data = (yaml_write_data_t *) data;
  mrb_str_buf_cat(write_data->mrb, write_data->str, (char *) buffer, size);
  return 1;
}


void raise_parser_problem(mrb_state *mrb, yaml_parser_t *parser)
{
  mrb_value problem_line = mrb_fixnum_value(parser->problem_mark.line);
  mrb_value problem_col = mrb_fixnum_value(parser->problem_mark.column);
  mrb_value problem_str = mrb_str_new_cstr(mrb, parser->problem);

  mrb_raisef(mrb, E_RUNTIME_ERROR, "%S at line %S column %S",
    problem_str, problem_line, problem_col);
}

mrb_value
node_to_value_with_aliases(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node, int use_scalar_aliases)
{
  /* YAML will return a NULL node if the input was empty */
  if (!node)
    return mrb_nil_value();

  switch (node->type)
  {
    case YAML_SCALAR_NODE:
    {
      const char *str = (char *) node->data.scalar.value;
      char *endptr;
      long long ll;
      double dd;

      /* if node is a YAML_PLAIN_SCALAR_STYLE */
      if (node->data.scalar.style == YAML_PLAIN_SCALAR_STYLE) {
        if (streql("~", str)) return mrb_nil_value();

        if (use_scalar_aliases) {
          /* Check if it is a null http://yaml.org/type/null.html */
          if (streql("nil", str) || streql("", str)
          #if MRUBY_YAML_NULL
            || streql("null", str) || streql("Null", str) || streql("NULL", str)
          #endif
            ) {
            return mrb_nil_value();
          /* Check if it is a Boolean http://yaml.org/type/bool.html */
          } else if (
            streql("true", str) || streql("True", str) || streql("TRUE", str)
          #if MRUBY_YAML_BOOLEAN_ON
            || streql("on", str) || streql("On", str) || streql("ON", str)
          #endif
          #if MRUBY_YAML_BOOLEAN_YES
            || streql("yes", str) || streql("Yes", str) || streql("YES", str)
          #endif
          #if MRUBY_YAML_BOOLEAN_SHORTHAND_YES
            || streql("y", str) || streql("Y", str)
          #endif
            ) {
            return mrb_true_value();
          } else if (
            streql("false", str) || streql("False", str) || streql("FALSE", str)
          #if MRUBY_YAML_BOOLEAN_OFF
            || streql("off", str) || streql("Off", str) || streql("OFF", str)
          #endif
          #if MRUBY_YAML_BOOLEAN_NO
            || streql("no", str) || streql("No", str)  || streql("NO", str)
          #endif
          #if MRUBY_YAML_BOOLEAN_SHORTHAND_NO
            || streql("n", str) || streql("N", str)
          #endif
            ) {
            return mrb_false_value();
          }
        }

        /* Check if it is a Fixnum */
        ll = strtoll(str, &endptr, 0);
        if (str != endptr && *endptr == '\0')
          return mrb_fixnum_value(ll);

        /* Check if it is a Float */
        dd = strtod(str, &endptr);
        if (str != endptr && *endptr == '\0')
          return mrb_float_value(mrb, dd);
      }

      /* Otherwise it is a String */
      return mrb_str_new(mrb, str, node->data.scalar.length);
    }

    case YAML_SEQUENCE_NODE:
    {
      /* Sequences are arrays in Ruby */
      mrb_value result = mrb_ary_new(mrb);
      yaml_node_item_t *item;

      int ai = mrb_gc_arena_save(mrb);

      for (item = node->data.sequence.items.start;
        item < node->data.sequence.items.top; item++)
      {
        yaml_node_t *child_node = yaml_document_get_node(document, *item);
        mrb_value child = node_to_value(mrb, document, child_node);

        mrb_ary_push(mrb, result, child);
        mrb_gc_arena_restore(mrb, ai);
      }

      return result;
    }

    case YAML_MAPPING_NODE:
    {
      /* Mappings are hashes in Ruby */
      mrb_value result = mrb_hash_new(mrb);
      yaml_node_t *key_node;
      yaml_node_t *value_node;
      yaml_node_pair_t *pair;
      mrb_value key, value;

      int ai = mrb_gc_arena_save(mrb);

      for (pair = node->data.mapping.pairs.start;
        pair < node->data.mapping.pairs.top; pair++)
      {
        key_node = yaml_document_get_node(document, pair->key);
        value_node = yaml_document_get_node(document, pair->value);

        key = node_to_value_key(mrb, document, key_node);
        value = node_to_value(mrb, document, value_node);

        mrb_hash_set(mrb, result, key, value);
        mrb_gc_arena_restore(mrb, ai);
      }

      return result;
    }

    default:
      return mrb_nil_value();
  }
}

mrb_value
node_to_value_key(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node)
{
  return node_to_value_with_aliases(mrb, document, node, 0);
}

mrb_value
node_to_value(mrb_state *mrb,
  yaml_document_t *document, yaml_node_t *node)
{
  return node_to_value_with_aliases(mrb, document, node, 1);
}

int value_to_node(mrb_state *mrb,
  yaml_document_t *document, mrb_value value)
{
  int node;

  switch (mrb_type(value))
  {
    case MRB_TT_ARRAY:
    {
      mrb_int len = RARRAY_LEN(value);
      mrb_int i;
      int ai = mrb_gc_arena_save(mrb);

      node = yaml_document_add_sequence(document, NULL,
        YAML_ANY_SEQUENCE_STYLE);

      for (i = 0; i < len; i++)
      {
        mrb_value child = mrb_ary_ref(mrb, value, i);
        int child_node = value_to_node(mrb, document, child);

        /* Add the child to the sequence */
        yaml_document_append_sequence_item(document, node, child_node);
        mrb_gc_arena_restore(mrb, ai);
      }

      break;
    }

    case MRB_TT_HASH:
    {
      /* Iterating a list of keys is slow, but it only
       * requires use of the interface defined in `hash.h`.
       */

      mrb_value keys = mrb_hash_keys(mrb, value);
      mrb_int len = RARRAY_LEN(keys);
      mrb_int i;
      int ai = mrb_gc_arena_save(mrb);

      node = yaml_document_add_mapping(document, NULL,
        YAML_ANY_MAPPING_STYLE);

      for (i = 0; i < len; i++)
      {
        mrb_value key = mrb_ary_ref(mrb, keys, i);
        mrb_value child = mrb_hash_get(mrb, value, key);

        int key_node = value_to_node(mrb, document, key);
        int child_node = value_to_node(mrb, document, child);

        /* Add the key/value pair to the mapping */
        yaml_document_append_mapping_pair(document, node,
          key_node, child_node);
        mrb_gc_arena_restore(mrb, ai);
      }

      break;
    }

    case MRB_TT_STRING:
    {
      yaml_scalar_style_t style = YAML_ANY_SCALAR_STYLE;
      yaml_char_t *value_chars;
      if (RSTRING_LEN(value) == 0) {
        /* If the String is empty, it may be reloaded as a nil instead of an
         * empty string, to avoid that place a quoted string instead */
        style = YAML_SINGLE_QUOTED_SCALAR_STYLE;
      }
      else if (!isalnum(RSTRING_PTR(value)[0])) {
        /* Easy mimic of https://github.com/ruby/psych/blob/v3.1.0/lib/psych/visitors/yaml_tree.rb#L307-L308 */
        style = YAML_DOUBLE_QUOTED_SCALAR_STYLE;
      }
      value_chars = (unsigned char *) RSTRING_PTR(value);
      node = yaml_document_add_scalar(document, NULL,
        value_chars, RSTRING_LEN(value), style);
      break;
    }

    default:
    {
      if (mrb_nil_p(value)) {
        /* http://yaml.org/type/null.html
           Canonical form */
        value = mrb_str_new_lit(mrb, "~");
        node = yaml_document_add_scalar(document, NULL,
                (unsigned char *) RSTRING_PTR(value), 1, YAML_ANY_SCALAR_STYLE);
      } else {
        /* Equivalent to `obj = obj#to_s` */
        node = value_to_node(mrb, document, mrb_obj_as_string(mrb, value));
      }
      break;
    }
  }

  return node;
}


void
mrb_mruby_yaml_gem_init(mrb_state *mrb)
{
  struct RClass *klass = mrb_define_module(mrb, "YAML");
  mrb_define_class_method(mrb, klass, "load", mrb_yaml_load, MRB_ARGS_REQ(1));
  mrb_define_class_method(mrb, klass, "dump", mrb_yaml_dump, MRB_ARGS_REQ(1));

  mrb_define_const(mrb, klass, "SUPPORT_NULL", mrb_bool_value(MRUBY_YAML_NULL));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_ON", mrb_bool_value(MRUBY_YAML_BOOLEAN_ON));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_YES", mrb_bool_value(MRUBY_YAML_BOOLEAN_YES));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_SHORTHAND_YES", mrb_bool_value(MRUBY_YAML_BOOLEAN_SHORTHAND_YES));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_OFF", mrb_bool_value(MRUBY_YAML_BOOLEAN_OFF));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_NO", mrb_bool_value(MRUBY_YAML_BOOLEAN_NO));
  mrb_define_const(mrb, klass, "SUPPORT_BOOLEAN_SHORTHAND_NO", mrb_bool_value(MRUBY_YAML_BOOLEAN_SHORTHAND_NO));
}


void
mrb_mruby_yaml_gem_final(mrb_state *mrb)
{
}
