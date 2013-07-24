
#include <stdio.h>
#include <yaml.h>
#include <mruby.h>
#include <mruby/compile.h>
#include <mruby/array.h>
#include <mruby/hash.h>


mrb_value mrb_yaml_open(mrb_state *mrb, mrb_value self);
static mrb_value yaml_node_to_mrb(mrb_state *mrb,
	yaml_document_t *document, yaml_node_t *node);
void mrb_mruby_yaml_gem_init(mrb_state *mrb);
void mrb_mruby_yaml_gem_final(mrb_state *mrb);


void
mruby_test()
{
	mrb_state *mrb = mrb_open();
	mrb_mruby_yaml_gem_init(mrb);
	
	/* Launch the test script */
	FILE *file = fopen("test.rb", "r");
	mrb_load_file(mrb, file);
	
	mrb_mruby_yaml_gem_final(mrb);
	mrb_close(mrb);
}


int
main(int argc, char *argv[])
{
	mruby_test();
	
	return EXIT_SUCCESS;
}


mrb_value
mrb_yaml_open(mrb_state *mrb, mrb_value self)
{
	yaml_parser_t parser;
	yaml_document_t document;
	FILE *file;
	char *filename;
	yaml_node_t *root;
	mrb_value result;
	
	/* Extract arguments */
	mrb_get_args(mrb, "z", &filename);
	
	/* Get a C file handle */
	file = fopen(filename, "rb");
	
	if (!file)
	{
		mrb_raise(mrb, E_RUNTIME_ERROR, "Could not load file");
		return mrb_nil_value();
	}
	
	/* Initialize the YAML parser */
	yaml_parser_initialize(&parser);
	yaml_parser_set_input_file(&parser, file);
	
	/* Load the document */
	yaml_parser_load(&parser, &document);
	
	/* Error handling */
	if (parser.error != YAML_NO_ERROR)
	{
		mrb_raise(mrb, E_RUNTIME_ERROR, parser.problem);
		return mrb_nil_value();
	}
	
	/* Convert the root node to an MRuby value */
	root = yaml_document_get_root_node(&document);
	result = yaml_node_to_mrb(mrb, &document, root);
	
	/* Clean up */
	yaml_document_delete(&document);
	yaml_parser_delete(&parser);
	fclose(file);
	
	return result;
}


mrb_value
yaml_node_to_mrb(mrb_state *mrb,
	yaml_document_t *document, yaml_node_t *node)
{
	switch (node->type)
	{
		case YAML_SCALAR_NODE:
		{
			/* Every scalar is a string */
			mrb_value result = mrb_str_new(mrb, node->data.scalar.value,
				node->data.scalar.length);
			return result;
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
				mrb_value child = yaml_node_to_mrb(mrb, document, child_node);
				
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
			
			int ai = mrb_gc_arena_save(mrb);
			
			for (pair = node->data.mapping.pairs.start;
				pair < node->data.mapping.pairs.top; pair++)
			{
				key_node = yaml_document_get_node(document, pair->key);
				value_node = yaml_document_get_node(document, pair->value);
				
				mrb_value key = yaml_node_to_mrb(mrb, document, key_node);
				mrb_value value = yaml_node_to_mrb(mrb, document, value_node);
				
				mrb_hash_set(mrb, result, key, value);
				mrb_gc_arena_restore(mrb, ai);
			}
			
			return result;
		}
		
		default:
			return mrb_nil_value();
	}
}


void
mrb_mruby_yaml_gem_init(mrb_state *mrb)
{
	struct RClass *klass = mrb_define_module(mrb, "YAML");
	mrb_define_class_method(mrb, klass, "open", mrb_yaml_open, ARGS_REQ(1));
}


void
mrb_mruby_yaml_gem_final(mrb_state *mrb)
{
}
